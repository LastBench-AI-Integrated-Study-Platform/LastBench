

import io
import re
import json
import random
import time
import requests
from typing import List, Dict, Tuple
from PIL import Image
import PyPDF2
import pytesseract
from pdf2image import convert_from_bytes

# Optional: DOCX support
try:
    from docx import Document
    DOCX_SUPPORT = True
except ImportError:
    DOCX_SUPPORT = False
    print("⚠️ python-docx not installed. DOCX files will not be supported.")

# ============================================================================
# CONFIGURATION
# ============================================================================

USE_FAST_MODE = True
ENABLE_TOPIC_ENRICHMENT = True

# ============================================================================
# TOPIC EXTRACTION & ENRICHMENT
# ============================================================================

def extract_main_topic(text: str) -> str:
    """Extract the main topic/subject from text."""
    text = ' '.join(text.split())
    
    capitalized_phrases = re.findall(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b', text)
    if capitalized_phrases:
        topic = max(capitalized_phrases, key=len)
        if len(topic) > 3:
            return topic
    
    patterns = [
        r'(?:about|on|regarding|concerning)\s+([A-Z][a-zA-Z\s]{3,30})',
        r'(?:topic|subject|theme):\s*([A-Z][a-zA-Z\s]{3,30})',
        r'^([A-Z][a-zA-Z\s]{3,30})',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return match.group(1).strip()
    
    words = text.split()
    meaningful_words = [w for w in words if len(w) > 3 and w.isalpha()]
    if meaningful_words:
        return ' '.join(meaningful_words[:3])
    
    return text[:50].strip()


def fetch_wikipedia_summary(topic: str, sentences: int = 10) -> Tuple[str, bool]:
    """Fetch Wikipedia summary for a topic."""
    try:
        print(f"🔍 Searching Wikipedia for: '{topic}'")
        
        url = "https://en.wikipedia.org/api/rest_v1/page/summary/" + topic.replace(" ", "_")
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            extract = data.get('extract', '')
            
            if extract and len(extract) > 100:
                print(f"✅ Found Wikipedia content: {len(extract)} characters")
                return extract, True
            else:
                print("⚠️ Wikipedia content too short, trying search...")
                return fetch_wikipedia_search(topic)
        else:
            print(f"⚠️ Wikipedia direct lookup failed, trying search...")
            return fetch_wikipedia_search(topic)
            
    except Exception as e:
        print(f"❌ Wikipedia fetch error: {e}")
        return "", False


def fetch_wikipedia_search(topic: str) -> Tuple[str, bool]:
    """Search Wikipedia and get the first result's summary."""
    try:
        search_url = "https://en.wikipedia.org/w/api.php"
        search_params = {
            "action": "query",
            "list": "search",
            "srsearch": topic,
            "format": "json",
            "srlimit": 1
        }
        
        search_response = requests.get(search_url, params=search_params, timeout=5)
        search_data = search_response.json()
        
        search_results = search_data.get('query', {}).get('search', [])
        
        if search_results:
            page_title = search_results[0]['title']
            print(f"🔍 Found page: {page_title}")
            
            content_params = {
                "action": "query",
                "prop": "extracts",
                "exintro": True,
                "explaintext": True,
                "titles": page_title,
                "format": "json"
            }
            
            content_response = requests.get(search_url, params=content_params, timeout=5)
            content_data = content_response.json()
            
            pages = content_data.get('query', {}).get('pages', {})
            for page_id, page_data in pages.items():
                extract = page_data.get('extract', '')
                if extract:
                    print(f"✅ Retrieved content: {len(extract)} characters")
                    return extract, True
        
        print("⚠️ No Wikipedia results found")
        return "", False
        
    except Exception as e:
        print(f"❌ Wikipedia search error: {e}")
        return "", False


def enrich_text_with_context(original_text: str) -> str:
    """Enrich short text by fetching relevant Wikipedia content."""
    if not ENABLE_TOPIC_ENRICHMENT:
        return original_text
    
    if len(original_text) > 500:
        print("📝 Text is substantial, skipping enrichment")
        return original_text
    
    print("🚀 Text is short, attempting topic enrichment...")
    
    topic = extract_main_topic(original_text)
    print(f"🎯 Detected topic: '{topic}'")
    
    wiki_content, success = fetch_wikipedia_summary(topic)
    
    if success and wiki_content:
        enriched = f"{original_text}\n\n--- Additional Context (from Wikipedia) ---\n{wiki_content}"
        print(f"✅ Text enriched: {len(original_text)} → {len(enriched)} characters")
        return enriched
    else:
        print("⚠️ Could not enrich text, using original")
        return original_text


# ============================================================================
# TEXT EXTRACTION FUNCTIONS (FIXED)
# ============================================================================

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Extract text from PDF using PyPDF2, fallback to OCR if needed."""
    text = ""
    
    try:
        print("📄 Attempting PyPDF2 text extraction...")
        reader = PyPDF2.PdfReader(io.BytesIO(pdf_bytes))
        
        for i, page in enumerate(reader.pages):
            try:
                extracted = page.extract_text()
                if extracted:
                    text += extracted + "\n"
                    print(f"  Page {i+1}: Extracted {len(extracted)} characters")
            except Exception as e:
                print(f"  Page {i+1}: Error - {e}")
        
        print(f"📊 Total extracted: {len(text)} characters")
        
        # If minimal text, try OCR
        if len(text.strip()) < 100:
            print("📸 Minimal text extracted, attempting OCR...")
            try:
                images = convert_from_bytes(pdf_bytes, dpi=300)
                ocr_text = ""
                
                for i, img in enumerate(images):
                    print(f"  OCR Page {i+1}...")
                    page_text = pytesseract.image_to_string(img, lang='eng')
                    ocr_text += page_text + "\n"
                    print(f"    Extracted {len(page_text)} characters")
                
                if len(ocr_text.strip()) > len(text.strip()):
                    print(f"✅ OCR successful: {len(ocr_text)} characters")
                    text = ocr_text
                else:
                    print("⚠️ OCR didn't improve results")
                    
            except Exception as ocr_error:
                print(f"❌ OCR failed: {ocr_error}")
                print("💡 Make sure poppler-utils and tesseract are installed")
        
        return text.strip()
        
    except Exception as e:
        print(f"❌ PDF extraction error: {e}")
        return ""


def extract_text_from_docx(docx_bytes: bytes) -> str:
    """Extract text from DOCX file."""
    if not DOCX_SUPPORT:
        raise Exception("DOCX support not available. Install: pip install python-docx")
    
    try:
        print("📝 Extracting text from DOCX...")
        doc = Document(io.BytesIO(docx_bytes))
        text = ""
        
        # Extract paragraphs
        for para in doc.paragraphs:
            if para.text.strip():
                text += para.text + "\n"
        
        # Extract tables
        for table in doc.tables:
            for row in table.rows:
                row_text = []
                for cell in row.cells:
                    if cell.text.strip():
                        row_text.append(cell.text.strip())
                if row_text:
                    text += " | ".join(row_text) + "\n"
        
        print(f"✅ Extracted {len(text)} characters from DOCX")
        return text.strip()
        
    except Exception as e:
        print(f"❌ DOCX extraction error: {e}")
        return ""


def extract_text_from_image(image_bytes: bytes) -> str:
    """Extract text from image using Tesseract OCR."""
    try:
        print("🖼️ Performing OCR on image...")
        
        # Open image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary
        if img.mode not in ('RGB', 'L'):
            print(f"  Converting image from {img.mode} to RGB")
            img = img.convert('RGB')
        
        print(f"  Image size: {img.size}")
        
        # Perform OCR
        text = pytesseract.image_to_string(img, lang='eng')
        
        print(f"✅ OCR extracted {len(text)} characters")
        
        if len(text.strip()) < 10:
            print("⚠️ Very little text extracted from image")
            print("💡 Ensure image quality is good and text is clearly visible")
        
        return text.strip()
        
    except Exception as e:
        print(f"❌ Image OCR error: {e}")
        print("💡 Make sure tesseract is installed and configured properly")
        return ""


def detect_file_type(filename: str) -> str:
    """Detect file type from filename extension."""
    filename_lower = filename.lower()
    
    if filename_lower.endswith('.pdf'):
        return 'pdf'
    elif filename_lower.endswith('.docx'):
        return 'docx'
    elif filename_lower.endswith('.doc'):
        return 'doc'
    elif filename_lower.endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tif', '.gif', '.webp')):
        return 'image'
    elif filename_lower.endswith('.txt'):
        return 'text'
    else:
        return 'unknown'


def extract_text_from_file(file_bytes: bytes, filename: str) -> str:
    """Universal text extractor with automatic format detection and topic enrichment."""
    
    print(f"\n{'='*60}")
    print(f"📁 Processing file: {filename}")
    print(f"📏 File size: {len(file_bytes)} bytes")
    print(f"{'='*60}\n")
    
    file_type = detect_file_type(filename)
    print(f"🔍 Detected file type: {file_type.upper()}")
    
    text = ""
    
    # Extract based on file type
    if file_type == 'pdf':
        text = extract_text_from_pdf(file_bytes)
        
    elif file_type == 'docx':
        if not DOCX_SUPPORT:
            print("⚠️ python-docx not installed, cannot process DOCX files")
            print("💡 Install with: pip install python-docx")
            return ""
        text = extract_text_from_docx(file_bytes)
        
    elif file_type == 'image':
        text = extract_text_from_image(file_bytes)
        
    elif file_type == 'text':
        try:
            print("📄 Processing as plain text file...")
            text = file_bytes.decode('utf-8', errors='ignore')
            print(f"✅ Decoded {len(text)} characters")
        except Exception as e:
            print(f"❌ Text decoding error: {e}")
            
    elif file_type == 'doc':
        print("⚠️ Old .DOC format not directly supported")
        print("💡 Please convert to .DOCX or PDF, or trying OCR as fallback...")
        try:
            text = extract_text_from_image(file_bytes)
        except:
            print("❌ Fallback extraction failed")
            
    else:
        print(f"⚠️ Unsupported file type: {filename}")
        print("💡 Trying OCR as last resort...")
        try:
            text = extract_text_from_image(file_bytes)
        except Exception as e:
            print(f"❌ Fallback OCR failed: {e}")
    
    # Report extraction results
    print(f"\n📊 Extraction Summary:")
    print(f"  - Extracted text length: {len(text)} characters")
    print(f"  - Word count: {len(text.split())}")
    print(f"  - Line count: {len(text.splitlines())}")
    
    # Enrich with Wikipedia if text is short
    if text and len(text.strip()) >= 10:
        print("\n🎯 Applying topic enrichment...")
        text = enrich_text_with_context(text)
    elif text:
        print("\n⚠️ Text too short for enrichment")
    
    return text


# ============================================================================
# OCR CLEANUP
# ============================================================================

def aggressive_ocr_cleanup(text: str) -> str:
    """Apply aggressive regex-based OCR error corrections."""
    replacements = {
        r'[|]UMAN': 'HUMAN',
        r'\|UMAN': 'HUMAN',
        r'\boO\b': '0',
        r'\bO\b(?=\d)': '0',
        r'(?<=\d)O\b': '0',
        r'\bl\b(?=\d)': '1',
        r'(?<=\d)l\b': '1',
        r'\brn\b': 'm',
        r'\bvv\b': 'w',
        r'\s+': ' ',
        r'\n\s*\n\s*\n+': '\n\n'
    }
    
    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text)
    
    return text.strip()


# ============================================================================
# CONTENT EXTRACTION
# ============================================================================

def extract_key_sentences(text: str, min_length: int = 30) -> List[str]:
    """Extract meaningful sentences from text."""
    sentences = re.split(r'[.!?]+', text)
    
    key_sentences = []
    for sent in sentences:
        sent = sent.strip()
        if len(sent) >= min_length and len(sent.split()) >= 5:
            if any(c.isalpha() for c in sent):
                key_sentences.append(sent)
    
    return key_sentences


def extract_key_terms(text: str) -> List[Dict[str, str]]:
    """Extract defined terms and concepts from text."""
    terms = []
    
    definition_patterns = [
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3})\s+is\s+(.+?)(?:[.;]|$)', 'definition'),
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3})\s+(?:means|refers to|describes)\s+(.+?)(?:[.;]|$)', 'definition'),
        (r'The\s+(.+?)\s+is\s+(.+?)(?:[.;]|$)', 'concept'),
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3}):\s+(.+?)(?:[.;]|$)', 'description'),
    ]
    
    for pattern, term_type in definition_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for term, definition in matches:
            term = term.strip()
            definition = definition.strip()
            
            if 2 < len(term) < 50 and 10 < len(definition) < 300:
                terms.append({
                    'term': term,
                    'definition': definition,
                    'type': term_type
                })
    
    return terms


# ============================================================================
# FAST QUIZ GENERATION
# ============================================================================

def generate_fast_quiz(text: str, num_questions: int = 5) -> Dict:
    """Generate quiz questions using rule-based approach."""
    random.seed(time.time())
    
    print("⚡ Using fast rule-based quiz generation")
    
    sentences = extract_key_sentences(text)
    terms = extract_key_terms(text)
    
    print(f"📊 Extracted {len(sentences)} sentences, {len(terms)} terms")
    
    if not sentences and not terms:
        print("⚠️ Insufficient content for quiz generation")
        return {"questions": [{
            "question": "What does the document discuss?",
            "options": [
                "The content requires review",
                "Unable to extract clear information",
                "Text was too short",
                "OCR quality was poor"
            ],
            "correct_answer": 0,
            "explanation": "The document did not contain sufficient extractable content."
        }]}
    
    random.shuffle(sentences)
    random.shuffle(terms)
    
    questions = []
    used_content = set()
    
    # Strategy 1: Definition-based questions
    for term_data in terms:
        if len(questions) >= num_questions:
            break
            
        term = term_data['term']
        definition = term_data['definition']
        
        if term.lower() in used_content:
            continue
        used_content.add(term.lower())
        
        other_terms = [t['term'] for t in terms if t['term'] != term]
        distractors = []
        
        if len(other_terms) >= 3:
            distractors = random.sample(other_terms, 3)
        else:
            distractors = other_terms.copy()
            generic_options = [
                "Not mentioned in the text",
                "None of the above",
                "Insufficient information",
                "All of the above"
            ]
            while len(distractors) < 3:
                distractor = random.choice(generic_options)
                if distractor not in distractors:
                    distractors.append(distractor)
        
        options = [term] + distractors[:3]
        random.shuffle(options)
        correct_idx = options.index(term)
        
        questions.append({
            "question": f"Which term best describes: \"{definition[:100]}...\"?" if len(definition) > 100 else f"What is described as: \"{definition}\"?",
            "options": options,
            "correct_answer": correct_idx,
            "explanation": f"'{term}' is defined as: {definition}"
        })
    
    print(f"✓ Generated {len(questions)} definition-based questions")
    
    # Strategy 2: Fill-in-the-blank
    for sentence in sentences:
        if len(questions) >= num_questions:
            break
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        words = sentence.split()
        important_words = [
            w for w in words 
            if len(w) > 4 and w.isalpha() and w.lower() not in ['which', 'where', 'there', 'these', 'those', 'their', 'would', 'could', 'should', 'about']
        ]
        
        if not important_words:
            continue
        
        answer = random.choice(important_words)
        question_text = sentence.replace(answer, "_____", 1)
        
        distractors = []
        for other_sent in sentences:
            if other_sent != sentence:
                other_words = [w for w in other_sent.split() if len(w) > 4 and w.isalpha()]
                if other_words:
                    candidate = random.choice(other_words)
                    if candidate.lower() != answer.lower() and candidate not in distractors:
                        distractors.append(candidate)
                        if len(distractors) >= 3:
                            break
        
        while len(distractors) < 3:
            variations = [
                answer.upper() if answer != answer.upper() else answer.lower(),
                answer + "s" if not answer.endswith('s') else answer[:-1],
                "Not " + answer
            ]
            for var in variations:
                if var not in distractors and var != answer:
                    distractors.append(var)
                    break
            if len(distractors) >= 3:
                break
        
        while len(distractors) < 3:
            distractors.append(f"Option {len(distractors) + 1}")
        
        options = [answer] + distractors[:3]
        random.shuffle(options)
        correct_idx = options.index(answer)
        
        questions.append({
            "question": f"Fill in the blank: {question_text}",
            "options": options,
            "correct_answer": correct_idx,
            "explanation": f"The correct word is '{answer}' based on the text."
        })
    
    print(f"✓ Generated {len(questions)} fill-in-the-blank questions")
    
    # Strategy 3: Comprehension questions
    attempt_count = 0
    max_attempts = 30
    
    while len(questions) < num_questions and sentences and attempt_count < max_attempts:
        attempt_count += 1
        sentence = random.choice(sentences)
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        true_statement = sentence if len(sentence) < 100 else sentence[:97] + "..."
        
        questions.append({
            "question": "According to the text, which statement is accurate?",
            "options": [
                true_statement,
                "The text does not discuss this topic",
                "The opposite of this is stated",
                "This information is not provided"
            ],
            "correct_answer": 0,
            "explanation": "This statement is directly from the source material."
        })
    
    print(f"✓ Generated {len(questions)} comprehension questions")
    
    if not questions:
        questions.append({
            "question": "What is the main topic discussed?",
            "options": [
                "The content requires further study",
                "No clear topic identified",
                "Multiple topics discussed",
                "Specific subject matter from the document"
            ],
            "correct_answer": 3,
            "explanation": "Review the document for the main subject matter."
        })
    
    final_questions = questions[:num_questions]
    print(f"✅ Returning {len(final_questions)} questions")
    
    return {"questions": final_questions}


# ============================================================================
# FAST FLASHCARD GENERATION
# ============================================================================

def generate_fast_flashcards(text: str, num_cards: int = 5) -> Dict:
    """Generate flashcards using rule-based approach."""
    random.seed(time.time())
    
    print("⚡ Using fast rule-based flashcard generation")
    
    sentences = extract_key_sentences(text)
    terms = extract_key_terms(text)
    
    print(f"📊 Extracted {len(sentences)} sentences, {len(terms)} terms")
    
    random.shuffle(sentences)
    random.shuffle(terms)
    
    flashcards = []
    used_content = set()
    
    # Strategy 1: Term definitions
    for term_data in terms:
        if len(flashcards) >= num_cards:
            break
            
        term = term_data['term']
        definition = term_data['definition']
        
        if term.lower() in used_content:
            continue
        used_content.add(term.lower())
        
        flashcards.append({
            "front": f"What is {term}?",
            "back": definition,
            "question": f"Define: {term}",
            "answer": definition
        })
    
    print(f"✓ Generated {len(flashcards)} definition flashcards")
    
    # Strategy 2: Sentence-based
    for sentence in sentences:
        if len(flashcards) >= num_cards:
            break
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        words = sentence.split()
        
        if len(words) > 12:
            split_point = len(words) // 2
            front_part = ' '.join(words[:split_point])
            back_part = ' '.join(words[split_point:])
            
            flashcards.append({
                "front": f"Complete: {front_part}...",
                "back": back_part,
                "question": front_part + "...",
                "answer": back_part
            })
        else:
            flashcards.append({
                "front": "Key fact:",
                "back": sentence,
                "question": "What does the text state?",
                "answer": sentence
            })
    
    print(f"✓ Generated {len(flashcards)} sentence-based flashcards")
    
    # Strategy 3: Fill remaining
    attempt_count = 0
    max_attempts = 20
    
    while len(flashcards) < num_cards and sentences and attempt_count < max_attempts:
        attempt_count += 1
        sentence = random.choice(sentences)
        
        if sentence[:30].lower() not in used_content:
            used_content.add(sentence[:30].lower())
            
            flashcards.append({
                "front": "Important concept:",
                "back": sentence,
                "question": "What is mentioned?",
                "answer": sentence
            })
    
    if not flashcards:
        flashcards.append({
            "front": "Study the material",
            "back": "Review the document for key concepts",
            "question": "What should you do?",
            "answer": "Carefully review the text"
        })
    
    final_flashcards = flashcards[:num_cards]
    print(f"✅ Returning {len(final_flashcards)} flashcards")
    
    return {"flashcards": final_flashcards}


# ============================================================================
# PUBLIC API
# ============================================================================

def generate_mcq_quiz(text: str, num_questions: int = 5) -> Dict:
    """Generate MCQ quiz from text."""
    return generate_fast_quiz(text, num_questions)


def generate_flashcards(text: str, num_cards: int = 5) -> Dict:
    """Generate flashcards from text."""
    return generate_fast_flashcards(text, num_cards)


def process_document(file_bytes: bytes, filename: str, num_questions: int = 5, num_cards: int = 5):
    """
    Process document and generate quiz/flashcards with automatic topic enrichment.
    
    Supported formats:
    - PDF files (.pdf)
    - DOCX files (.docx) - requires python-docx
    - Images (.png, .jpg, .jpeg, .bmp, .tiff, .gif, .webp) - requires tesseract
    - Text files (.txt)
    """
    
    # Extract text from file
    text = extract_text_from_file(file_bytes, filename)
    
    # Check if extraction was successful
    if not text or len(text.strip()) < 20:
        error_msg = "Could not extract sufficient text from document"
        details = f"Only {len(text.strip())} characters extracted"
        
        print(f"\n❌ {error_msg}")
        print(f"   {details}")
        print("\n💡 Troubleshooting tips:")
        print("   - For PDFs: Ensure the PDF is not scanned/image-based")
        print("   - For Images: Install tesseract-ocr on your system")
        print("   - For DOCX: Install python-docx (pip install python-docx)")
        print("   - Check if the file is corrupted")
        
        return {
            "error": error_msg,
            "details": details,
            "troubleshooting": [
                "Ensure file is not corrupted",
                "For images: Install tesseract-ocr",
                "For DOCX: Install python-docx",
                "For PDFs: Ensure text is selectable, not scanned"
            ]
        }
    
    print(f"\n✅ Successfully extracted {len(text)} characters")
    
    # Clean up OCR errors
    print("🧹 Cleaning text...")
    text = aggressive_ocr_cleanup(text)
    
    # Generate quiz
    print(f"\n🧠 Generating {num_questions} quiz questions...")
    quiz_data = generate_mcq_quiz(text, num_questions)
    
    # Generate flashcards
    print(f"📚 Generating {num_cards} flashcards...")
    flashcard_data = generate_flashcards(text, num_cards)
    
    print("\n✅ Processing complete!")
    
    return {
        "text": text[:500],  # Return first 500 chars as preview
        "full_text_length": len(text),
        "quiz": quiz_data,
        "flashcards": flashcard_data,
        "file_type": detect_file_type(filename),
        "success": True
    }
