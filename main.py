from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from planlama import router as planlama_router

app = FastAPI(
    title="Sınav Planlama API",
    description="YZM 2126 Veritabanı Sistemlerine Giriş Projesi Backend API",
    version="1.0.0"
)

# Frontend farklı porttan çalıştığında backend'e istek atabilsin diye CORS açık.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Tüm planlama endpointleri /api altında çalışır.
app.include_router(planlama_router, prefix="/api")


@app.get("/")
def home():
    return {
        "message": "Sınav Planlama API çalışıyor",
        "docs": "http://127.0.0.1:8000/docs",
        "api_prefix": "/api"
    }