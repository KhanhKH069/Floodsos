from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.schemas import ChatRequest, ChatResponse
from app.services.chatbot import ChatbotService

app = FastAPI(title="Flood FAQ + Hotline Chatbot", version="1.0.0")
bot = ChatbotService()

STATIC_DIR = Path(__file__).resolve().parent / "static"

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/api/chat", response_model=ChatResponse)
def chat(request: ChatRequest):
    reply, state, intent, suggestions, data = bot.process(request.session_id, request.message)
    return ChatResponse(
        session_id=request.session_id,
        reply=reply,
        state=state,
        intent=intent,
        suggestions=suggestions,
        data=data,
    )
