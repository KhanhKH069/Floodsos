import re

HOTLINE_KEYWORDS = {
    "hotline", "đường dây nóng", "duong day nong", "số điện thoại", "so dien thoai",
    "liên hệ", "lien he", "công an", "cuu thuong", "cứu thương",
    "115", "113", "114", "tình nguyện", "tinh nguyen", "thiện nguyện", "thien nguyen",
    "ban chỉ huy", "pctt", "tkcn", "cứu trợ"
}
GREETING_KEYWORDS = {"xin chào", "chào", "hello", "hi", "alo"}


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def contains_any(text: str, keywords: set[str]) -> bool:
    return any(k in text for k in keywords)


def detect_intent(message: str, current_state: str = "NORMAL") -> str:
    text = normalize_text(message)

    greeting_phrases = {"xin chào", "chào", "hello", "alo", "hi"}
    if text in greeting_phrases or (len(text.split()) <= 2 and text.startswith("chào")):
        return "greeting"

    if contains_any(text, HOTLINE_KEYWORDS):
        return "hotline_lookup"

    return "faq"
