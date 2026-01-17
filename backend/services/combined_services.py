"""
Combined services module for LastBench
ULTRA-FAST VERSION - Instant quiz/flashcard generation (< 5 seconds total)
Uses hybrid approach: Rule-based generation with optional LLM fallback
"""

import io
import re
import json
import random
from typing import List, Dict
from PIL import Image
import PyPDF2
import pytesseract
from pdf2image import convert_from_bytes

# ============================================================================
# CONFIGURATION
# ============================================================================

# Set to True for instant generation, False for LLM generation
USE_FAST_MODE = True  # ← Change this to False if you want to use LLM (slow)

# Only import torch/transformers if LLM mode is enabled
if not USE_FAST_MODE:
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM
    
    MODEL_NAME = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
    CUDA_AVAILABLE = torch.cuda.is_available()
    DEVICE = "cuda" if CUDA_AVAILABLE else "cpu"
    TORCH_DTYPE = torch.float16 if CUDA_AVAILABLE else torch.float32
    
    tokenizer = None
    model = None


# ============================================================================
# TEXT EXTRACTION FUNCTIONS
# ============================================================================

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Extract text from PDF using PyPDF2, fallback to OCR if minimal text found."""
    try:
        reader = PyPDF2.PdfReader(io.BytesIO(pdf_bytes))
        text = ""

        for page in reader.pages:
            extracted = page.extract_text()
            if extracted:
                text += extracted + "\n"

        if len(text.strip()) < 100:
            print("📸 PDF has minimal text, using OCR...")
            images = convert_from_bytes(pdf_bytes)
            text = ""
            for img in images:
                text += pytesseract.image_to_string(img) + "\n"

        return text.strip()
    except Exception as e:
        print(f"❌ PDF extraction error: {e}")
        return ""


def extract_text_from_image(image_bytes: bytes) -> str:
    """Extract text from image using Tesseract OCR."""
    try:
        img = Image.open(io.BytesIO(image_bytes))
        return pytesseract.image_to_string(img).strip()
    except Exception as e:
        print(f"❌ Image extraction error: {e}")
        return ""


# ============================================================================
# OCR CLEANUP (INSTANT - < 0.5 seconds)
# ============================================================================

def aggressive_ocr_cleanup(text: str) -> str:
    """Apply aggressive regex-based OCR error corrections - INSTANT."""
    replacements = {
        r'[|]UMAN': 'HUMAN',
        r'\|UMAN': 'HUMAN',
        r'\boO\b': '(7)',
        r'\bO\b(?=\d)': '0',
        r'(?<=\d)O\b': '0',
        r'\bl\b(?=\d)': '1',
        r'\brn\b': 'm',
        r'\bvv\b': 'w',
        r'\s+': ' ',
        r'\n\s*\n\s*\n+': '\n\n'
    }
    for p, r in replacements.items():
        text = re.sub(p, r, text)
    return text.strip()


# ============================================================================
# FAST RULE-BASED GENERATION (INSTANT - < 1 second)
# ============================================================================

def extract_key_sentences(text: str, min_length: int = 30) -> List[str]:
    """Extract meaningful sentences from text."""
    # Split by sentence delimiters
    sentences = re.split(r'[.!?]+', text)
    
    # Filter meaningful sentences
    key_sentences = []
    for sent in sentences:
        sent = sent.strip()
        # Must be long enough and have multiple words
        if len(sent) >= min_length and len(sent.split()) >= 5:
            # Avoid sentences that are just numbers or symbols
            if any(c.isalpha() for c in sent):
                key_sentences.append(sent)
    
    return key_sentences


def extract_key_terms(text: str) -> List[Dict[str, str]]:
    """Extract defined terms and concepts from text."""
    terms = []
    
    # Pattern 1: "X is Y" definitions
    definition_patterns = [
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+is\s+(.+?)(?:[.;]|$)', 'definition'),
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+means\s+(.+?)(?:[.;]|$)', 'definition'),
        (r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+refers to\s+(.+?)(?:[.;]|$)', 'definition'),
        (r'The\s+(.+?)\s+is\s+(.+?)(?:[.;]|$)', 'concept'),
    ]
    
    for pattern, term_type in definition_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for term, definition in matches:
            term = term.strip()
            definition = definition.strip()
            
            # Only add if both term and definition are reasonable
            if 2 < len(term) < 50 and 5 < len(definition) < 200:
                terms.append({
                    'term': term,
                    'definition': definition,
                    'type': term_type
                })
    
    return terms


def generate_fast_quiz(text: str, num_questions: int = 3) -> Dict:
    """
    Generate quiz questions using rule-based approach - INSTANT!
    No LLM needed - completes in < 1 second.
    """
    print("⚡ Using fast rule-based quiz generation")
    
    sentences = extract_key_sentences(text)
    terms = extract_key_terms(text)
    
    questions = []
    used_content = set()  # Avoid duplicates
    
    # Strategy 1: Definition-based questions (highest quality)
    for term_data in terms:
        if len(questions) >= num_questions:
            break
            
        term = term_data['term']
        definition = term_data['definition']
        
        if term.lower() in used_content:
            continue
        used_content.add(term.lower())
        
        # Get other terms as distractors
        other_terms = [t['term'] for t in terms if t['term'] != term]
        distractors = random.sample(other_terms, min(3, len(other_terms)))
        
        # Add generic distractors if needed
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
            "question": f"Which term best describes: \"{definition[:100]}...\"?",
            "options": options,
            "correct_answer": correct_idx,
            "explanation": f"'{term}' is defined in the text as: {definition}"
        })
    
    # Strategy 2: Fill-in-the-blank from key sentences
    for sentence in sentences:
        if len(questions) >= num_questions:
            break
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        words = sentence.split()
        
        # Find important words (nouns/verbs - usually capitalized or longer)
        important_words = [
            w for w in words 
            if len(w) > 4 and w.isalpha() and not w.lower() in ['which', 'where', 'there', 'these', 'those']
        ]
        
        if not important_words:
            continue
        
        # Pick a word to blank out
        answer = random.choice(important_words)
        
        # Create question with blank
        question_text = sentence.replace(answer, "_____", 1)
        
        # Generate distractors from other sentences
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
        
        # Pad with variations of the answer
        while len(distractors) < 3:
            variations = [
                answer.upper(),
                answer.lower(),
                answer + "s",
                "Not " + answer
            ]
            for var in variations:
                if var not in distractors and var != answer:
                    distractors.append(var)
                    break
            if len(distractors) >= 3:
                break
        
        options = [answer] + distractors[:3]
        random.shuffle(options)
        correct_idx = options.index(answer)
        
        questions.append({
            "question": f"Fill in the blank: {question_text}",
            "options": options,
            "correct_answer": correct_idx,
            "explanation": f"The correct word is '{answer}' based on the original text."
        })
    
    # Strategy 3: True/False style comprehension questions
    while len(questions) < num_questions and sentences:
        sentence = sentences[len(questions) % len(sentences)]
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        # Create a true statement question
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
    
    # Ensure we have the requested number of questions
    if not questions:
        # Ultimate fallback
        questions.append({
            "question": "What is the main topic of the provided text?",
            "options": [
                "The content requires further study",
                "No clear topic identified",
                "Multiple topics discussed",
                "Specific subject matter from the document"
            ],
            "correct_answer": 3,
            "explanation": "Review the document for the main subject matter."
        })
    
    return {"questions": questions[:num_questions]}


def generate_fast_flashcards(text: str, num_cards: int = 3) -> Dict:
    """
    Generate flashcards using rule-based approach - INSTANT!
    No LLM needed - completes in < 1 second.
    """
    print("⚡ Using fast rule-based flashcard generation")
    
    sentences = extract_key_sentences(text)
    terms = extract_key_terms(text)
    
    flashcards = []
    used_content = set()
    
    # Strategy 1: Term definition flashcards (best quality)
    for term_data in terms:
        if len(flashcards) >= num_cards:
            break
            
        term = term_data['term']
        definition = term_data['definition']
        
        if term.lower() in used_content:
            continue
        used_content.add(term.lower())
        
        flashcards.append({
            "front": f"Define: {term}",
            "back": definition,
            "question": f"What is {term}?",
            "answer": definition
        })
    
    # Strategy 2: Question-answer pairs from sentences
    for sentence in sentences:
        if len(flashcards) >= num_cards:
            break
        
        if sentence[:30].lower() in used_content:
            continue
        used_content.add(sentence[:30].lower())
        
        words = sentence.split()
        
        # For longer sentences, split into Q&A
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
            # For shorter sentences, make it a recall question
            flashcards.append({
                "front": "Recall this key fact:",
                "back": sentence,
                "question": "What does the text state about this topic?",
                "answer": sentence
            })
    
    # Strategy 3: Key concepts from remaining content
    while len(flashcards) < num_cards and sentences:
        idx = len(flashcards) % len(sentences)
        sentence = sentences[idx]
        
        if sentence[:30].lower() not in used_content:
            used_content.add(sentence[:30].lower())
            
            flashcards.append({
                "front": "Key concept from the text:",
                "back": sentence,
                "question": "What is an important point mentioned?",
                "answer": sentence
            })
    
    # Ensure we have the requested number of cards
    if not flashcards:
        flashcards.append({
            "front": "Study the source material",
            "back": "Review the original document for key concepts and definitions",
            "question": "What should you do next?",
            "answer": "Carefully review the provided text for important information"
        })
    
    return {"flashcards": flashcards[:num_cards]}


# ============================================================================
# LLM-BASED GENERATION (SLOW - Only used if USE_FAST_MODE = False)
# ============================================================================

def _initialize_model():
    """Lazy load the LLM model (only called if USE_FAST_MODE = False)."""
    global tokenizer, model
    
    if tokenizer is None or model is None:
        print(f"🚀 Loading {MODEL_NAME}...")
        print(f"   Device: {DEVICE} | Dtype: {TORCH_DTYPE}")
        
        try:
            tokenizer = AutoTokenizer.from_pretrained(
                MODEL_NAME, 
                trust_remote_code=True
            )
            tokenizer.pad_token = tokenizer.eos_token
            
            model = AutoModelForCausalLM.from_pretrained(
                MODEL_NAME,
                device_map="auto",
                dtype=TORCH_DTYPE,
                low_cpu_mem_usage=True,
                trust_remote_code=True
            )
            model.eval()
            print("✅ Model loaded successfully!")
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise
    
    return tokenizer, model


def generate_llm_quiz(text: str, num_questions: int = 3) -> Dict:
    """Generate quiz using LLM - SLOW (2-5 minutes on CPU)."""
    global tokenizer, model
    tokenizer, model = _initialize_model()
    
    text_excerpt = text[:1000]
    
    prompt = f"""Generate {num_questions} multiple choice questions.

Text: {text_excerpt}

Return ONLY JSON array:
[
  {{"question": "What is...?", "options": ["A", "B", "C", "D"], "correct_answer": 0}}
]

JSON:"""

    try:
        inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=400).to(DEVICE)
        
        print("🧠 Generating with LLM (this may take 2-5 minutes)...")
        
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=300,
                do_sample=False,
                num_beams=1,
                pad_token_id=tokenizer.eos_token_id,
            )
        
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        json_match = re.search(r'\[.*\]', result, re.DOTALL)
        
        if json_match:
            parsed = json.loads(json_match.group(0))
            return {"questions": parsed}
    
    except Exception as e:
        print(f"❌ LLM generation failed: {e}")
    
    print("⚠️ LLM failed, falling back to fast generation")
    return generate_fast_quiz(text, num_questions)


def generate_llm_flashcards(text: str, num_cards: int = 3) -> Dict:
    """Generate flashcards using LLM - SLOW (1-3 minutes on CPU)."""
    global tokenizer, model
    tokenizer, model = _initialize_model()
    
    text_excerpt = text[:1000]
    
    prompt = f"""Generate {num_cards} flashcard pairs.

Text: {text_excerpt}

Return ONLY JSON array:
[
  {{"question": "What is...?", "answer": "It is..."}}
]

JSON:"""

    try:
        inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=400).to(DEVICE)
        
        print("📚 Generating with LLM (this may take 1-3 minutes)...")
        
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=300,
                do_sample=False,
                num_beams=1,
                pad_token_id=tokenizer.eos_token_id,
            )
        
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        json_match = re.search(r'\[.*\]', result, re.DOTALL)
        
        if json_match:
            parsed = json.loads(json_match.group(0))
            return {"flashcards": parsed}
    
    except Exception as e:
        print(f"❌ LLM generation failed: {e}")
    
    print("⚠️ LLM failed, falling back to fast generation")
    return generate_fast_flashcards(text, num_cards)


# ============================================================================
# PUBLIC API - AUTO-SELECTS FAST OR LLM MODE
# ============================================================================

def generate_mcq_quiz(text: str, num_questions: int = 3) -> Dict:
    """
    Generate MCQ quiz from text.
    
    Mode selected by USE_FAST_MODE configuration:
    - True: Instant rule-based generation (< 1 second)
    - False: LLM generation (2-5 minutes on CPU)
    """
    if USE_FAST_MODE:
        return generate_fast_quiz(text, num_questions)
    else:
        return generate_llm_quiz(text, num_questions)


def generate_flashcards(text: str, num_cards: int = 3) -> Dict:
    """
    Generate flashcards from text.
    
    Mode selected by USE_FAST_MODE configuration:
    - True: Instant rule-based generation (< 1 second)
    - False: LLM generation (1-3 minutes on CPU)
    """
    if USE_FAST_MODE:
        return generate_fast_flashcards(text, num_cards)
    else:
        return generate_llm_flashcards(text, num_cards)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def process_document(file_bytes: bytes, file_type: str, num_questions: int = 3, num_cards: int = 3):
    """
    Process a document and generate both MCQ quiz and flashcards.
    
    Total time with USE_FAST_MODE=True: < 5 seconds
    Total time with USE_FAST_MODE=False: 3-8 minutes
    """
    # Extract text
    if file_type == 'pdf':
        text = extract_text_from_pdf(file_bytes)
    else:
        text = extract_text_from_image(file_bytes)
    
    if not text or len(text.strip()) < 50:
        return {
            "error": "Could not extract sufficient text from document"
        }
    
    # Clean OCR text (instant)
    text = aggressive_ocr_cleanup(text)
    
    # Generate quiz and flashcards
    quiz_data = generate_mcq_quiz(text, num_questions)
    flashcard_data = generate_flashcards(text, num_cards)
    
    return {
        "text": text[:500],
        "quiz": quiz_data,
        "flashcards": flashcard_data
    }