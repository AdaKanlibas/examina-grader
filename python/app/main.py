"""
Examina Python Service
Handles: SymPy verification, Manim video rendering, Mathpix OCR proxy

Phase 2: All endpoints are stubs returning structured responses.
Phase 3: Real SymPy logic, Mathpix integration.
Phase 4: Manim rendering + ElevenLabs TTS pipeline.
"""

import os
from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from app.routes import verify, render, ocr

SERVICE_SECRET = os.getenv("SERVICE_SECRET", "")

app = FastAPI(
    title="Examina Python Service",
    version="0.1.0",
    docs_url="/docs" if os.getenv("ENV") != "production" else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("NEXT_APP_URL", "http://localhost:3000")],
    allow_methods=["POST", "GET"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(verify.router, prefix="/verify", tags=["verification"])
app.include_router(render.router, prefix="/render", tags=["video"])
app.include_router(ocr.router, prefix="/ocr", tags=["ocr"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "examina-python", "version": "0.1.0"}
