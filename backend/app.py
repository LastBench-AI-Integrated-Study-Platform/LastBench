import os
import traceback
from pathlib import Path

os.environ["TOKENIZERS_PARALLELISM"] = "false"

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
from pypdf import PdfReader
from pdf2image import convert_from_path
import pytesseract
from groq import Groq
import faiss
from langchain_text_splitters import RecursiveCharacterTextSplitter
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

# ================= CONFIG =================
load_dotenv()

# Required packages:
# pip install fastapi uvicorn python-multipart pypdf pdf2image pytesseract sentence-transformers faiss-cpu python-dotenv groq langchain-text-splitters

# System dependencies (macOS example):
# brew install tesseract poppler

# ================= INIT =================
app = FastAPI(title="PDF Question Answering with Groq")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.getenv("GROQ_API_KEY"))
embedder = SentenceTransformer("all-MiniLM-L6-v2")

# Global state (simple - for development only)
vector_store = None
documents = []

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


# ================= HELPERS =================
def extract_text(pdf_path: Path | str) -> str:
    """Try native text extraction → OCR fallback"""
    path = Path(pdf_path)
    print(f"Extracting: {path.name}")

    # 1. Native PDF text
    try:
        reader = PdfReader(path)
        text = "".join(page.extract_text() or "" for page in reader.pages)
        text = text.strip()
        if len(text) > 250:
            print(f"  → Native text extracted ({len(text)} chars)")
            return text
    except Exception as e:
        print(f"  Native extraction failed: {e}")

    # OCR fallback with EasyOCR (better for handwriting)
    print("  → Trying EasyOCR (better handwriting support)...")
    try:
        reader = easyocr.Reader(['en'], gpu=False)
        images = convert_from_path(path, dpi=200)
        full_text = []
        for i, img in enumerate(images, 1):
            # Preprocess: grayscale + enhance contrast
            img_cv = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
            gray = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
            enhanced = cv2.convertScaleAbs(gray, alpha=1.5, beta=0)
            result = reader.readtext(enhanced, detail=0, paragraph=True)
            page_text = " ".join(result)
            full_text.append(f"[Page {i}]\n{page_text.strip()}\n")
        return "\n".join(full_text).strip()
    except Exception as e:
        print("EasyOCR failed:", e)
        # fall back to pytesseract or placeholder


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

    if not documents:
        raise ValueError("No meaningful chunks after splitting")

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
            model="llama-3.3-70b-versatile",          # ← WORKING as of January 2026
            # Alternative fast option: "llama-4-scout-17b-16e-instruct"
            messages=[{"role": "user", "content": prompt}],
            temperature=0.25,
            max_tokens=400,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print("Groq API error:", str(e))
        return f"[Generation failed: {str(e)}]"


# ================= ENDPOINT =================
@app.post("/analyze")
async def analyze_notes_and_questions(
    notes: UploadFile = File(...),
    questions: UploadFile = File(...)
):
    try:
        # Save uploaded files
        notes_path = UPLOAD_DIR / notes.filename
        questions_path = UPLOAD_DIR / questions.filename

        with notes_path.open("wb") as f:
            shutil.copyfileobj(notes.file, f)

        with questions_path.open("wb") as f:
            shutil.copyfileobj(questions.file, f)

        # Extract text
        notes_text = extract_text(notes_path)
        questions_text = extract_text(questions_path)

        print(f"Notes length: {len(notes_text):,} chars")
        print(f"Questions length: {len(questions_text):,} chars")

        # Build vector store from notes
        build_vector_store(notes_text)

        # Parse questions
        raw_questions = [line.strip() for line in questions_text.splitlines() if line.strip()]
        question_list = [q for q in raw_questions if len(q) > 5][:25]

        if not question_list:
            raise HTTPException(400, detail="No valid questions found in the questions file")

        # Generate answers
        results = []
        for q in question_list:
            context = retrieve_context(q)
            answer = generate_answer(context, q)
            results.append({"question": q, "answer": answer})

        return {"results": results}

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Server error: {str(e)}\nCheck terminal for full traceback"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)