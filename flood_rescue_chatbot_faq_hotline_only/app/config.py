from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
INDEX_DIR = BASE_DIR / "index"
DB_PATH = BASE_DIR / "rescue_chatbot.db"

TOP_K = 3
SIMILARITY_THRESHOLD = 0.22
APP_NAME = "Flood Rescue Chatbot"
