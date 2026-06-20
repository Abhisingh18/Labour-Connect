from fastapi import APIRouter

from app.api.routes import admin, auth, categories, customer, profile, uploads, worker

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(categories.router)
api_router.include_router(profile.router)
api_router.include_router(customer.router)
api_router.include_router(worker.router)
api_router.include_router(uploads.router)
api_router.include_router(admin.router)
