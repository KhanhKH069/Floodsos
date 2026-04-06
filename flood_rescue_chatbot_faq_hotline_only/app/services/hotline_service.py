import json
import re
from dataclasses import dataclass
from typing import Dict, List, Optional

from app.config import DATA_DIR


TYPE_KEYWORDS = {
    "police": ["công an", "cong an", "113", "an ninh", "trật tự", "trat tu", "police"],
    "ambulance": ["cứu thương", "cuu thuong", "115", "cấp cứu", "cap cuu", "xe cứu thương", "y tế", "y te", "ambulance"],
    "rescue": ["cứu hộ", "cuu ho", "cứu nạn", "cuu nan", "cứu trợ", "cuu tro", "114", "pccc", "phòng cháy", "phong chay", "cnch"],
    "volunteer": ["tình nguyện", "tinh nguyen", "thiện nguyện", "thien nguyen", "nhóm hỗ trợ", "doi ho tro", "volunteer"],
}

TYPE_LABELS = {
    "police": "công an",
    "police_local": "công an địa phương",
    "ambulance": "cấp cứu y tế",
    "ambulance_local": "cứu thương địa phương",
    "rescue": "cứu hộ/cứu nạn",
    "volunteer": "đội tình nguyện viên",
}


@dataclass
class HotlineSearchResult:
    province: Optional[str]
    matched_types: List[str]
    contacts: List[Dict]
    general_contacts: List[Dict]
    has_placeholder: bool


class HotlineService:
    def __init__(self) -> None:
        with open(DATA_DIR / "hotlines.json", "r", encoding="utf-8") as f:
            payload = json.load(f)
        self.general_contacts = payload.get("general_emergency", [])
        self.provinces = payload.get("provinces", [])

    def _normalize(self, text: str) -> str:
        text = text.strip().lower()
        return re.sub(r"\s+", " ", text)

    def detect_province(self, query: str) -> Optional[Dict]:
        norm = self._normalize(query)
        best = None
        best_score = 0
        for item in self.provinces:
            aliases = [item.get("province", "")] + item.get("aliases", [])
            score = 0
            for alias in aliases:
                alias_norm = self._normalize(alias)
                if alias_norm and alias_norm in norm:
                    score = max(score, len(alias_norm))
            if score > best_score:
                best_score = score
                best = item
        return best

    def detect_types(self, query: str) -> List[str]:
        norm = self._normalize(query)
        matched = []
        for kind, keywords in TYPE_KEYWORDS.items():
            if any(k in norm for k in keywords):
                matched.append(kind)
        return matched

    def search(self, query: str) -> HotlineSearchResult:
        province = self.detect_province(query)
        matched_types = self.detect_types(query)
        province_contacts: List[Dict] = []
        has_placeholder = False

        if province:
            for contact in province.get("contacts", []):
                ctype = contact.get("type", "")
                if matched_types:
                    if ctype not in matched_types and ctype.replace("_local", "") not in matched_types:
                        continue
                province_contacts.append(contact)
                has_placeholder = has_placeholder or bool(contact.get("is_placeholder"))

        general_contacts = self.general_contacts
        if matched_types:
            general_contacts = [
                c for c in self.general_contacts
                if c.get("type") in matched_types or c.get("type", "").replace("_local", "") in matched_types
            ]

        return HotlineSearchResult(
            province=province.get("province") if province else None,
            matched_types=matched_types,
            contacts=province_contacts,
            general_contacts=general_contacts,
            has_placeholder=has_placeholder,
        )

    def _format_contact(self, item: Dict) -> str:
        label = TYPE_LABELS.get(item.get("type", ""), item.get("type", "liên hệ"))
        phone = item.get("phone", "")
        availability = item.get("availability")
        description = item.get("description")
        suffix = []
        if availability:
            suffix.append(availability)
        if description:
            suffix.append(description)
        suffix_text = f" ({'; '.join(suffix)})" if suffix else ""
        return f"- {item.get('name', 'Liên hệ')} [{label}]: {phone}{suffix_text}"

    def format_results(self, query: str) -> str:
        result = self.search(query)

        if not result.province:
            lines = [
                "Tôi đã nhận diện đây là yêu cầu tra cứu hotline hỗ trợ. Anh/chị vui lòng cho biết thêm tỉnh/thành để tôi trả về đúng số liên hệ địa phương.",
                "\nTrong lúc chờ, các đầu số khẩn cấp toàn quốc có thể dùng ngay:",
            ]
            lines.extend(self._format_contact(item) for item in result.general_contacts)
            lines.append("\nVí dụ: 'Hotline cứu trợ Nghệ An', 'Số cứu thương Đà Nẵng', 'Công an hỗ trợ Hà Nội'.")
            return "\n".join(lines)

        lines = [f"Hotline hỗ trợ cho {result.province}:"]
        if result.contacts:
            lines.extend(self._format_contact(item) for item in result.contacts)
        else:
            lines.append("- Chưa có nhóm số theo đúng loại hỗ trợ này trong dữ liệu địa phương.")

        if result.general_contacts:
            lines.append("\nĐầu số khẩn cấp toàn quốc nên gọi song song khi tình huống nguy hiểm:")
            lines.extend(self._format_contact(item) for item in result.general_contacts)

        if result.has_placeholder:
            lines.append(
                "\nLưu ý: một số số địa phương trong danh sách hiện đang ở trạng thái CẬP_NHẬT_TAY_* để nhập thủ công. "
                "Anh/chị cần thay bằng số thật trước khi đưa chatbot vào sử dụng thực tế."
            )
        return "\n".join(lines)
