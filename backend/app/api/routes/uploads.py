from fastapi import APIRouter, File, HTTPException, UploadFile, status

from app.api.deps import WorkerUser
from app.services import uploads as upload_service

router = APIRouter(prefix="/uploads", tags=["uploads"])


@router.post("/kyc")
async def upload_kyc_document(
    _: WorkerUser,
    file: UploadFile = File(...),
):
    """Validate and store a KYC document; returns the stored relative path.

    Send the returned `url` to POST /worker/kyc. Workers only.
    """
    try:
        path = await upload_service.save_kyc_file(file)
    except upload_service.UploadError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return {"url": path}
