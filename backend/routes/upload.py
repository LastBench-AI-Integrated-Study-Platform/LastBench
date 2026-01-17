from fastapi import APIRouter, UploadFile, File
from services.combined_services import extract_text_from_pdf, extract_text_from_image, aggressive_ocr_cleanup, correct_ocr_batch

router = APIRouter()

@router.post("/file")
async def upload(file: UploadFile = File(...)):
    data = await file.read()

    if file.filename.endswith(".pdf"):
        text = extract_text_from_pdf(data)
    else:
        text = extract_text_from_image(data)

    clean = aggressive_ocr_cleanup(text)
    final = correct_ocr_batch(clean)

    return {"text": final}
