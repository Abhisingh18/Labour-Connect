"""Secure local file storage for KYC documents.

MVP stores validated files on local disk with random names. Production should
push to private object storage (S3) with server-side encryption + signed URLs
and run an AV scan (ClamAV) — see SECURITY.md (Layer 7).
"""
import os
import uuid

from fastapi import UploadFile

from app.core.config import settings

ALLOWED = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "application/pdf": ".pdf",
}

# Magic-byte signatures to confirm the real file type (don't trust the header).
_SIGNATURES = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",   # followed by WEBP at offset 8
    b"%PDF": "application/pdf",
}


class UploadError(Exception):
    pass


def _sniff(head: bytes) -> str | None:
    for sig, mime in _SIGNATURES.items():
        if head.startswith(sig):
            if mime == "image/webp" and head[8:12] != b"WEBP":
                continue
            return mime
    return None


async def save_kyc_file(file: UploadFile) -> str:
    if file.content_type not in ALLOWED:
        raise UploadError("Unsupported file type. Use JPG, PNG, WEBP or PDF.")

    data = await file.read()
    if len(data) == 0:
        raise UploadError("Empty file.")
    if len(data) > settings.UPLOAD_MAX_BYTES:
        raise UploadError("File too large (max 5 MB).")

    sniffed = _sniff(data[:16])
    if sniffed is None or sniffed != file.content_type:
        raise UploadError("File content does not match its type.")

    ext = ALLOWED[file.content_type]
    name = f"{uuid.uuid4().hex}{ext}"
    target_dir = os.path.join(settings.UPLOAD_DIR, "kyc")
    os.makedirs(target_dir, exist_ok=True)
    path = os.path.join(target_dir, name)
    with open(path, "wb") as fh:
        fh.write(data)

    # Relative URL/path stored against the worker profile.
    return f"kyc/{name}"
