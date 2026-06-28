"""
Pydantic schemas shared across all Python service routes.
These mirror the TypeScript types in web/src/types/grading.ts.
"""

from pydantic import BaseModel, Field
from typing import Literal, Optional


# ─── SymPy verification ───────────────────────────────────────────────────────

class VerifyRequest(BaseModel):
    """Ask SymPy whether the student's answer matches the expected answer."""
    submission_id: str
    mark_id: str
    student_answer: str = Field(..., description="LaTeX or Python expression")
    expected_answer: str = Field(..., description="LaTeX or Python expression")
    variables: list[str] = Field(default_factory=list, description="Variable names, e.g. ['x', 'y']")


class VerifyResponse(BaseModel):
    submission_id: str
    mark_id: str
    result: Literal["agree", "disagree", "not_applicable", "error"]
    simplified_diff: Optional[str] = None
    note: Optional[str] = None


# ─── Manim video render ───────────────────────────────────────────────────────

class RenderRequest(BaseModel):
    question_id: str
    language: Literal["tr", "en"] = "tr"
    solution_steps: list[str] = Field(..., description="LaTeX steps for animation")
    voiceover_text: str


class RenderResponse(BaseModel):
    question_id: str
    language: str
    storage_path: str
    duration_seconds: int
    cached: bool


# ─── OCR (Mathpix proxy) ──────────────────────────────────────────────────────

class OCRRequest(BaseModel):
    image_url: Optional[str] = None
    image_base64: Optional[str] = None
    mime_type: str = "image/jpeg"


class OCRResponse(BaseModel):
    latex: str
    confidence: float
    text: Optional[str] = None
