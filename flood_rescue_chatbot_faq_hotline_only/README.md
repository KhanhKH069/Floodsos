# Flood FAQ + Hotline Chatbot

Phiên bản rút gọn của chatbot lũ lụt, chỉ giữ lại 2 chức năng:

- FAQ về an toàn, sơ cứu, điện nước, sơ tán, nước bẩn, thực phẩm sau lũ
- Tra cứu hotline cứu trợ, công an, cứu thương theo tỉnh/thành từ file JSON nhập tay

## 1. Cài đặt

```bash
cd flood_rescue_chatbot_faq_hotline_only
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python scripts/build_index.py
uvicorn app.main:app --reload
```

Mở:
- Chat UI: `http://127.0.0.1:8000`

## 2. Chức năng còn lại

### FAQ
Ví dụ câu hỏi:
- `Mất điện khi nhà đang ngập phải làm sao?`
- `Điện giật trong vùng ngập xử lý thế nào?`
- `Nước lũ dính vào vết thương có nguy hiểm không?`

### Hotline
Ví dụ câu hỏi:
- `Hotline cứu trợ Hà Nội`
- `Số cứu thương Đà Nẵng`
- `Công an hỗ trợ TP.HCM`
- `Hotline cứu trợ Nghệ An`

## 3. Dữ liệu

Thư mục `data/` gồm:
- `knowledge_base.json`: kho FAQ
- `hotlines.json`: danh sách hotline nhập tay theo tỉnh/thành

### Cập nhật hotline thủ công
1. Mở `data/hotlines.json`
2. Tìm tỉnh/thành trong mảng `provinces`
3. Cập nhật `phone` cho từng contact
4. Nếu còn `is_placeholder: true` nghĩa là số đó vẫn cần được thay bằng số thật

## 4. Cấu trúc thư mục

```text
flood_rescue_chatbot_faq_hotline_only/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── schemas.py
│   ├── static/
│   │   ├── index.html
│   │   ├── app.js
│   │   └── styles.css
│   └── services/
│       ├── chatbot.py
│       ├── hotline_service.py
│       ├── nlu.py
│       └── retrieval.py
├── data/
│   ├── knowledge_base.json
│   └── hotlines.json
├── index/
├── scripts/
│   └── build_index.py
├── requirements.txt
└── README.md
```

## 5. Ghi chú

- Bot này không còn tiếp nhận cứu hộ, không tạo phiếu, không có admin, không theo dõi mã yêu cầu.
- Nếu sửa `knowledge_base.json`, hãy chạy lại `python scripts/build_index.py`.
- Nếu chỉ sửa `hotlines.json`, không cần build lại index.
