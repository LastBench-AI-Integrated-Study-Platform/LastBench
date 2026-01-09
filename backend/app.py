import os
os.environ["GRPC_DNS_RESOLVER"] = "native"

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import shutil, numpy as np
from pypdf import PdfReader
from pdf2image import convert_from_path
import google.generativeai as genai
import faiss
from langchain_text_splitters import RecursiveCharacterTextSplitter
from dotenv import load_dotenv

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
gemini = genai.GenerativeModel("gemini-2.5-flash")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

vector_store = None
documents = []

# ---------- HELPERS ----------

def extract_text_auto(pdf_path):
    reader = PdfReader(pdf_path)
    text = "".join(page.extract_text() or "" for page in reader.pages)

    if len(text.strip()) > 150:
        return text

    pages = convert_from_path(pdf_path, dpi=300)
    full_text = ""
    prompt = "Extract handwritten text accurately. Fix grammar. Return ONLY text."

    for page in pages:
        res = gemini.generate_content([prompt, page])
        full_text += res.text + "\n"

    return full_text


def safe_embed(text):
    try:
        return genai.embed_content(
            model="text-embedding-004",
            content=text
        )["embedding"]
    except Exception as e:
        print("Embedding failed:", e)
        return None


def build_vector_store(notes_text):
    global vector_store, documents

    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    documents = splitter.split_text(notes_text)

    embeddings = []
    for doc in documents:
        emb = safe_embed(doc)
        if emb:
            embeddings.append(emb)

    if not embeddings:
        raise RuntimeError("No embeddings generated")

    embeddings = np.array(embeddings).astype("float32")
    vector_store = faiss.IndexFlatL2(embeddings.shape[1])
    vector_store.add(embeddings)


def safe_generate(prompt):
    try:
        return gemini.generate_content(prompt).text
    except Exception as e:
        print("Generation failed:", e)
        return "Answer generation failed."


def answer_question(question):
    query_emb = safe_embed(question)
    if query_emb is None:
        return "Embedding service unavailable"

    query_emb = np.array([query_emb], dtype="float32")
    _, idx = vector_store.search(query_emb, 3)

    context = " ".join(documents[i] for i in idx[0])

    prompt = f"""
Answer ONLY from context.

Context:
{context}

Question:
{question}

Answer:
"""
    return safe_generate(prompt)


# ---------- API ----------

@app.post("/analyze")
async def analyze(notes: UploadFile = File(...), questions: UploadFile = File(...)):
    os.makedirs("uploads", exist_ok=True)

    notes_path = f"uploads/{notes.filename}"
    q_path = f"uploads/{questions.filename}"

    with open(notes_path, "wb") as f:
        shutil.copyfileobj(notes.file, f)
    with open(q_path, "wb") as f:
        shutil.copyfileobj(questions.file, f)

    notes_text = extract_text_auto(notes_path)
    build_vector_store(notes_text)

    q_text = extract_text_auto(q_path)
    questions_list = [q for q in q_text.split("\n") if q.strip()]

    results = [{"question": q, "answer": answer_question(q)} for q in questions_list]
    return {"results": results}
