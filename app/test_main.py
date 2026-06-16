"""
Unit tests for Document Q&A API
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_list_documents():
    """Test list documents endpoint"""
    response = client.get("/documents")
    assert response.status_code == 200
    data = response.json()
    assert "documents" in data
    assert len(data["documents"]) >= 3

def test_ask_question_valid():
    """Test asking a valid question"""
    payload = {
        "question": "What is Kubernetes?",
        "document_id": "doc1"
    }
    response = client.post("/ask", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert "confidence" in data
    assert "inference_time_ms" in data
    assert data["confidence"] > 0

def test_ask_question_invalid_document():
    """Test asking question with invalid document"""
    payload = {
        "question": "What is this?",
        "document_id": "nonexistent"
    }
    response = client.post("/ask", json=payload)
    assert response.status_code == 404

def test_ask_question_empty_question():
    """Test with empty question"""
    payload = {
        "question": "",
        "document_id": "doc1"
    }
    response = client.post("/ask", json=payload)
    assert response.status_code == 400

def test_metrics_endpoint():
    """Test metrics endpoint"""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"api_requests_total" in response.content
    assert b"api_request_duration_seconds" in response.content

def test_ask_question_default_document():
    """Test asking question with default document"""
    payload = {
        "question": "What is DevOps?"
    }
    response = client.post("/ask", json=payload)
    assert response.status_code == 200
    assert response.json()["question"] == "What is DevOps?"
