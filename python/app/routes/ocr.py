"""
POST /ocr
Mathpix v3 OCR proxy — extracts LaTeX from images of handwritten math.

Phase 2: Returns stub response.
Phase 3: Real Mathpix v3/text API call, EU endpoint.
"""

from fastapi import APIRouter
from app.models.schemas import OCRRequest, OCRResponse

router = APIRouter()


@router.post("", response_model=OCRResponse)
def extract_latex(req: OCRRequest) -> OCRResponse:
    """
    Phase 2 stub.
    Phase 3 will call Mathpix v3/text:
      POST https://api.mathpix.com/v3/text
      Headers: app_id, app_key
      Body: { src: base64_image, formats: ["latex_simplified"] }
    """
    # TODO Phase 3:
    # import httpx
    # response = httpx.post(
    #     "https://api.mathpix.com/v3/text",
    #     headers={"app_id": MATHPIX_APP_ID, "app_key": MATHPIX_APP_KEY},
    #     json={"src": f"data:{req.mime_type};base64,{req.image_base64}", "formats": ["latex_simplified"]}
    # )
    # data = response.json()
    # return OCRResponse(latex=data["latex_simplified"], confidence=data.get("confidence", 0.9))

    return OCRResponse(
        latex=r"f'(x) = 3x^2 + 4x - 5",
        confidence=0.0,
        text="Phase 2 stub — Mathpix OCR active in Phase 3",
    )
