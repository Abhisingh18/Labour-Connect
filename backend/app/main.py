from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.core.middleware import SecurityHeadersMiddleware

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Backend API for Labour Connect — a service marketplace (customer, worker, admin).",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Security headers on every response (OWASP secure headers).
app.add_middleware(SecurityHeadersMiddleware)

if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.get("/", tags=["health"])
def root():
    return {"status": "ok", "service": settings.PROJECT_NAME}


@app.get("/health", tags=["health"])
def health():
    return {"status": "healthy"}


app.include_router(api_router, prefix=settings.API_V1_PREFIX)
