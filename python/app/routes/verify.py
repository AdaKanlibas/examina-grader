"""
POST /verify
SymPy symbolic verification of student answers.

Phase 2: Returns stub response.
Phase 3: Real SymPy logic — parses student and expected answers,
         simplifies the difference, returns agree/disagree.
"""

from fastapi import APIRouter
from app.models.schemas import VerifyRequest, VerifyResponse

router = APIRouter()


@router.post("", response_model=VerifyResponse)
def verify_answer(req: VerifyRequest) -> VerifyResponse:
    """
    Phase 2 stub — always returns 'not_applicable'.
    Phase 3 implementation will use sympy.simplify(student - expected) == 0.
    """
    # TODO Phase 3: implement real SymPy verification
    # from sympy import sympify, simplify, symbols
    # syms = symbols(" ".join(req.variables)) if req.variables else ()
    # try:
    #     student_expr = sympify(req.student_answer)
    #     expected_expr = sympify(req.expected_answer)
    #     diff = simplify(student_expr - expected_expr)
    #     result = "agree" if diff == 0 else "disagree"
    # except Exception as e:
    #     result = "error"

    return VerifyResponse(
        submission_id=req.submission_id,
        mark_id=req.mark_id,
        result="not_applicable",
        note="Phase 2 stub — SymPy verification active in Phase 3",
    )
