const sessionId = localStorage.getItem("flood_chat_session") || crypto.randomUUID();
localStorage.setItem("flood_chat_session", sessionId);

const messagesEl = document.getElementById("messages");
const suggestionsEl = document.getElementById("suggestions");
const formEl = document.getElementById("chat-form");
const inputEl = document.getElementById("message-input");

function addMessage(role, text) {
  const wrapper = document.createElement("div");
  wrapper.className = `message ${role}`;
  const bubble = document.createElement("div");
  bubble.className = "bubble";
  bubble.textContent = text;
  wrapper.appendChild(bubble);
  messagesEl.appendChild(wrapper);
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

function renderSuggestions(suggestions) {
  suggestionsEl.innerHTML = "";
  (suggestions || []).forEach((item) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "suggestion-chip";
    btn.textContent = item;
    btn.onclick = () => {
      inputEl.value = item;
      inputEl.focus();
    };
    suggestionsEl.appendChild(btn);
  });
}

async function sendMessage(message) {
  addMessage("user", message);
  inputEl.value = "";

  const response = await fetch("/api/chat", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({ session_id: sessionId, message })
  });

  const data = await response.json();
  addMessage("bot", data.reply);
  renderSuggestions(data.suggestions);
}

formEl.addEventListener("submit", async (event) => {
  event.preventDefault();
  const message = inputEl.value.trim();
  if (!message) return;
  await sendMessage(message);
});

addMessage("bot", "Xin chào, tôi là chatbot FAQ và hotline hỗ trợ lũ lụt. Bạn có thể hỏi kiến thức an toàn hoặc tra cứu hotline theo tỉnh/thành.");
renderSuggestions([
  "Hotline cứu trợ Hà Nội",
  "Số cứu thương Đà Nẵng",
  "Mất điện khi nhà đang ngập phải làm sao?"
]);
