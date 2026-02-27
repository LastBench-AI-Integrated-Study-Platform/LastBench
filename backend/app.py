import os
import traceback
from pathlib import Path
import shutil

os.environ["TOKENIZERS_PARALLELISM"] = "false"

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles      # ← ADD THIS
from dotenv import load_dotenv

from pypdf import PdfReader
from pdf2image import convert_from_path
import pytesseract

from groq import Groq
import faiss
from langchain_text_splitters import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer

from routes.auth_routes import router as auth_router
from routes.insights_routes import router as insights_router
from routes.doubt_routes import router as doubt_router
from routes import combined_routes

# ================= CONFIG =================
load_dotenv()

# ================= INIT =================
app = FastAPI(title="PDF Question Answering with Groq")

# ✅ CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Include routers
app.include_router(auth_router)
app.include_router(insights_router)
app.include_router(doubt_router)
app.include_router(combined_routes.router, prefix="/api")

# ✅ Serve uploaded files as static assets
# Ensures /uploads/doubt_images/filename.jpg works in the browser
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
(UPLOAD_DIR / "doubt_images").mkdir(exist_ok=True)   # ← ensure subfolder exists too
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")  # ← ADD THIS

# ================= GROQ + EMBEDDINGS =================
client = Groq(api_key=os.getenv("GROQ_API_KEY"))
embedder = SentenceTransformer("all-MiniLM-L6-v2")

vector_store = None
documents = []


# ================= HELPERS =================
def extract_text(pdf_path: Path | str) -> str:
    path = Path(pdf_path)
    print(f"Extracting: {path.name}")

    try:
        reader = PdfReader(path)
        text = "".join(page.extract_text() or "" for page in reader.pages).strip()
        if len(text) > 250:
            print(f"  → Native text extracted ({len(text)} chars)")
            return text
    except Exception as e:
        print(f"  Native extraction failed: {e}")

    return ""


def build_vector_store(text: str):
    global vector_store, documents

    if not text.strip():
        raise ValueError("No text could be extracted from the document")

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=550,
        chunk_overlap=80,
        separators=["\n\n", "\n", ". ", " ", ""]
    )

    documents = splitter.split_text(text)
    print(f"Created {len(documents)} chunks")

    embeddings = embedder.encode(documents, show_progress_bar=False, convert_to_numpy=True)
    embeddings = embeddings.astype("float32")

    dim = embeddings.shape[1]
    vector_store = faiss.IndexFlatL2(dim)
    vector_store.add(embeddings)


def retrieve_context(question: str, k: int = 4) -> str:
    if vector_store is None or not documents:
        return ""

    q_emb = embedder.encode([question], convert_to_numpy=True).astype("float32")
    distances, indices = vector_store.search(q_emb, min(k, len(documents)))

    relevant_chunks = [documents[i] for i in indices[0] if i < len(documents)]
    return "\n\n".join(relevant_chunks)


def generate_answer(context: str, question: str) -> str:
    if len(context.strip()) < 40:
        return "Not enough relevant information found in the provided notes."

    prompt = f"""You are a helpful teaching assistant.
Answer the question concisely and accurately using **only** the provided context.
If the context doesn't contain the answer, say so clearly.

Context:
{context}

Question: {question}

Answer:"""

    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.25,
            max_tokens=400,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"[Generation failed: {str(e)}]"


# ================= ENDPOINT =================
@app.post("/analyze")
async def analyze_notes_and_questions(
    notes: UploadFile = File(...),
    questions: UploadFile = File(...)
):
    try:
        notes_path = UPLOAD_DIR / notes.filename
        questions_path = UPLOAD_DIR / questions.filename

        with notes_path.open("wb") as f:
            shutil.copyfileobj(notes.file, f)

        with questions_path.open("wb") as f:
            shutil.copyfileobj(questions.file, f)

        notes_text = extract_text(notes_path)
        questions_text = extract_text(questions_path)

        build_vector_store(notes_text)

        raw_questions = [line.strip() for line in questions_text.splitlines() if line.strip()]
        question_list = [q for q in raw_questions if len(q) > 5][:25]

        if not question_list:
            raise HTTPException(status_code=400, detail="No valid questions found")

        results = []
        for q in question_list:
            context = retrieve_context(q)
            answer = generate_answer(context, q)
            results.append({"question": q, "answer": answer})

        return {"results": results}

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")