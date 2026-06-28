"""
POST /render
Manim animation + ElevenLabs TTS video generation.

Phase 2: Returns stub response.
Phase 4: Real Manim scene generation, ElevenLabs TTS, MP4 output to Supabase storage.
"""

from fastapi import APIRouter
from app.models.schemas import RenderRequest, RenderResponse

router = APIRouter()


@router.post("", response_model=RenderResponse)
def render_video(req: RenderRequest) -> RenderResponse:
    """
    Phase 2 stub.
    Phase 4 will:
      1. Generate Manim scene Python file from solution_steps
      2. Render headless: manim -qm scene.py ExplainerScene --format mp4
      3. Generate voiceover via ElevenLabs TTS (Turkish voice first)
      4. Mux audio + video with ffmpeg
      5. Upload to Supabase storage
      6. Write cache record to video_cache table
    """
    return RenderResponse(
        question_id=req.question_id,
        language=req.language,
        storage_path=f"videos/stub/{req.question_id}_{req.language}.mp4",
        duration_seconds=0,
        cached=False,
    )
