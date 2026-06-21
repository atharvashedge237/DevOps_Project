import os
import logging
import asyncio
from typing import Optional
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest
import time
import json

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Document Q&A API",
    description="LLM-powered document question-answering service",
    version="1.0.0"
)

# Prometheus metrics
request_count = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration in seconds',
    ['endpoint']
)

inference_duration = Histogram(
    'inference_duration_seconds',
    'LLM inference duration in seconds',
    ['model']
)

# Pydantic models
class QuestionRequest(BaseModel):
    question: str
    document_id: Optional[str] = None
    max_tokens: Optional[int] = 150

class QuestionResponse(BaseModel):
    question: str
    answer: str
    confidence: float
    inference_time_ms: float

# Mock document store (Need to use actual API calls)
DOCUMENTS = {
    "doc1": "Kubernetes is an open-source container orchestration platform. It automates deployment, scaling, and management of containerized applications.",
    "doc2": "DevOps is a set of practices that combines software development and IT operations. It aims to shorten development cycles and increase deployment frequency.",
    "doc3": "Infrastructure as Code (IaC) allows you to manage infrastructure using configuration files instead of manual processes."
}

@app.on_event("startup")
async def startup_event():
    """Application startup event"""
    logger.info("Document Q&A API starting up...")
    logger.info(f"Loaded {len(DOCUMENTS)} documents")

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event"""
    logger.info("Document Q&A API shutting down...")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse(
        status_code=200,
        content={"status": "healthy", "version": "1.0.0"}
    )

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()

@app.post("/ask", response_model=QuestionResponse)
async def ask_question(request: QuestionRequest):
    """
    Ask a question about a document
    
    Args:
        request: QuestionRequest containing question and optional document_id
        
    Returns:
        QuestionResponse with answer and metadata
    """
    with request_duration.labels(endpoint='/ask').time():
        try:
            # Validate input
            if not request.question:
                raise HTTPException(status_code=400, detail="Question cannot be empty")
            
            # Select document (default to doc1 if not specified)
            doc_id = request.document_id or "doc1"
            if doc_id not in DOCUMENTS:
                raise HTTPException(status_code=404, detail=f"Document {doc_id} not found")
            
            document = DOCUMENTS[doc_id]
            
            # Mock LLM inference
            start_time = time.time()
            answer = await mock_llm_inference(request.question, document)
            inference_time = (time.time() - start_time) * 1000
            
            # Record metrics
            inference_duration.labels(model='mock-llm').observe(inference_time / 1000)
            request_count.labels(method='POST', endpoint='/ask', status=200).inc()
            
            logger.info(f"Question answered: {request.question[:50]}... (inference: {inference_time:.2f}ms)")
            
            return QuestionResponse(
                question=request.question,
                answer=answer,
                confidence=0.92,
                inference_time_ms=inference_time
            )
            
        except HTTPException:
            request_count.labels(method='POST', endpoint='/ask', status=400).inc()
            raise
        except Exception as e:
            request_count.labels(method='POST', endpoint='/ask', status=500).inc()
            logger.error(f"Error processing question: {str(e)}")
            raise HTTPException(status_code=500, detail=str(e))

@app.get("/documents")
async def list_documents():
    """List all available documents"""
    request_count.labels(method='GET', endpoint='/documents', status=200).inc()
    return JSONResponse(
        status_code=200,
        content={
            "documents": [
                {"id": doc_id, "preview": content[:100] + "..."}
                for doc_id, content in DOCUMENTS.items()
            ]
        }
    )

@app.post("/upload")
async def upload_document(document_id: str, file: UploadFile = File(...)):
    """Upload a new document"""
    try:
        content = await file.read()
        DOCUMENTS[document_id] = content.decode('utf-8')
        request_count.labels(method='POST', endpoint='/upload', status=200).inc()
        logger.info(f"Document uploaded: {document_id}")
        return JSONResponse(
            status_code=200,
            content={"message": f"Document {document_id} uploaded successfully"}
        )
    except Exception as e:
        request_count.labels(method='POST', endpoint='/upload', status=500).inc()
        logger.error(f"Upload failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def mock_llm_inference(question: str, document: str) -> str:
    """
    Mock LLM inference function
    In production, replace with actual LLM API calls (OpenAI, LLaMA, etc.)
    """
    # If Azure OpenAI is configured, use it. Otherwise fall back to the simple mock.
    azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    azure_key = os.getenv("AZURE_OPENAI_KEY")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")  # deployment name (model) in Azure OpenAI
    max_tokens = int(os.getenv("MAX_TOKENS", "150"))

    if azure_endpoint and azure_key and deployment:
        # Build a prompt that provides the document context and the user question
        prompt = (
            "You are an assistant that answers questions using only the provided document. "
            "If the answer is not contained in the document, say you cannot answer.\n\n"
            f"Document:\n{document}\n\nQuestion:\n{question}\n\nAnswer:"
        )

        url = f"{azure_endpoint.rstrip('/')}/openai/deployments/{deployment}/chat/completions?api-version=2023-05-15"

        payload = {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant. Answer briefly and cite the document when relevant."},
                {"role": "user", "content": prompt}
            ],
            "max_tokens": max_tokens,
            "temperature": 0.0
        }

        import httpx

        headers = {
            "api-key": azure_key,
            "Content-Type": "application/json"
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                r = await client.post(url, headers=headers, json=payload)
                r.raise_for_status()
                data = r.json()

                # Azure Chat completions response: choices[0].message.content
                if "choices" in data and len(data["choices"]) > 0:
                    choice = data["choices"][0]
                    # Support both chat-style and completion-style responses
                    if "message" in choice and "content" in choice["message"]:
                        return choice["message"]["content"].strip()
                    if "text" in choice:
                        return choice["text"].strip()

                # Fallback to a simple message if response shape unexpected
                return "(no answer returned from LLM)"
        except Exception as e:
            logger.error(f"Error calling Azure OpenAI: {e}")
            # Fall back to mock behaviour on error

    # --- Fallback mock inference ---
    await asyncio.sleep(0.1)
    keywords = question.lower().split()
    sentences = document.split('.')
    best_sentence = max(
        (s.strip() for s in sentences if any(kw in s.lower() for kw in keywords)),
        default=sentences[0].strip(),
        key=len
    )
    return best_sentence + "."

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        log_level="info"
    )

import asyncio