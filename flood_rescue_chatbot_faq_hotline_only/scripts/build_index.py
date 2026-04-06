import json
from pathlib import Path

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
INDEX_DIR = BASE_DIR / "index"

INDEX_DIR.mkdir(exist_ok=True, parents=True)

with open(DATA_DIR / "knowledge_base.json", "r", encoding="utf-8") as f:
    kb = json.load(f)

docs = []
corpus = []
for item in kb:
    text = " ".join(item["question_variations"] + [item["answer"]])
    docs.append(item)
    corpus.append(text)

vectorizer = TfidfVectorizer(ngram_range=(1, 2), lowercase=True)
matrix = vectorizer.fit_transform(corpus)

joblib.dump(vectorizer, INDEX_DIR / "vectorizer.joblib")
joblib.dump(matrix, INDEX_DIR / "matrix.joblib")
with open(INDEX_DIR / "docs.json", "w", encoding="utf-8") as f:
    json.dump(docs, f, ensure_ascii=False, indent=2)

print(f"Built retrieval index with {len(docs)} docs at {INDEX_DIR}")
