from typing import Dict, List, Tuple

from app.services.hotline_service import HotlineService
from app.services.nlu import detect_intent
from app.services.retrieval import Retriever


class ChatbotService:
    def __init__(self) -> None:
        self.retriever = Retriever()
        self.hotlines = HotlineService()

    def process(self, session_id: str, message: str) -> Tuple[str, str, str, List[str], Dict]:
        user_intent = detect_intent(message)

        if user_intent == "greeting":
            reply = (
                "Xin chào, tôi là chatbot FAQ và hotline hỗ trợ lũ lụt. "
                "Tôi có thể trả lời câu hỏi thường gặp về an toàn, sơ cứu, điện nước, sơ tán "
                "và tra cứu hotline cứu trợ, công an, cứu thương theo tỉnh/thành."
            )
            suggestions = [
                "Hotline cứu trợ Hà Nội",
                "Số cứu thương Đà Nẵng",
                "Mất điện khi nhà đang ngập phải làm sao?",
            ]
            return reply, "NORMAL", "greeting", suggestions, {}

        if user_intent == "hotline_lookup":
            reply = self.hotlines.format_results(message)
            suggestions = [
                "Hotline cứu trợ Nghệ An",
                "Công an hỗ trợ Hà Nội",
                "Cấp cứu TP.HCM",
            ]
            return reply, "NORMAL", "hotline_lookup", suggestions, {"type": "hotline_lookup"}

        result = self.retriever.answer(message)
        suggestions = [
            "Điện giật trong vùng ngập xử lý thế nào?",
            "Nước lũ dính vào vết thương có nguy hiểm không?",
            "Hotline cứu trợ Đà Nẵng",
        ]
        return result["reply"], "NORMAL", "faq", suggestions, {"type": "faq", "found": result.get("found", False)}
