import json
from pathlib import Path
from typing import Dict, List

import joblib
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

from app.config import INDEX_DIR, SIMILARITY_THRESHOLD, TOP_K


class Retriever:
    def __init__(self) -> None:
        self.vectorizer = joblib.load(INDEX_DIR / "vectorizer.joblib")
        self.matrix = joblib.load(INDEX_DIR / "matrix.joblib")
        with open(INDEX_DIR / "docs.json", "r", encoding="utf-8") as f:
            self.docs = json.load(f)

    def search(self, query: str, top_k: int = TOP_K) -> List[Dict]:
        query_vec = self.vectorizer.transform([query])
        scores = cosine_similarity(query_vec, self.matrix)[0]
        indices = np.argsort(scores)[::-1][:top_k]
        return [
            {
                "score": float(scores[idx]),
                "doc": self.docs[int(idx)],
            }
            for idx in indices
        ]

    def answer(self, query: str) -> Dict:
        results = self.search(query)
        best = results[0] if results else None
        if not best or best["score"] < SIMILARITY_THRESHOLD:
            return {
                "found": False,
                "reply": (
                    "Tôi chưa tìm thấy câu trả lời phù hợp trong kho tri thức hiện tại. "
                    "Anh/chị có thể diễn đạt lại, gửi rõ địa điểm, hoặc yêu cầu gặp cán bộ hỗ trợ."
                ),
                "matches": results,
            }

        doc = best["doc"]
        return {
            "found": True,
            "reply": doc["answer"],
            "matches": results,
            "category": doc.get("category", "faq"),
        }
