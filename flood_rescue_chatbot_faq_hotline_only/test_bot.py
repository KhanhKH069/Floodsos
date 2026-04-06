import sys
from pathlib import Path

# Add the project root to sys.path
sys.path.append(str(Path(__file__).resolve().parent))

from app.services.chatbot import ChatbotService

def test():
    print("Initializing ChatbotService...")
    bot = ChatbotService()
    print("Initialization done.")
    
    message = "Mất điện khi nhà đang ngập phải làm sao?"
    print(f"Processing message: {message}")
    reply, state, intent, suggestions, data = bot.process("test_session", message)
    print("Response received:")
    print(f"Reply: {reply}")
    print(f"Intent: {intent}")

if __name__ == "__main__":
    test()
