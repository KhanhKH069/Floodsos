// controllers/chatController.js — Chatbot response logic
exports.chat = (req, res) => {
    const userMsg = req.body.message ? req.body.message.toLowerCase() : "";
    let reply = "Xin lỗi, tôi chưa hiểu ý bạn.";

    if (userMsg.includes('xin chào') || userMsg.includes('hi'))          reply = "Chào bạn! Tôi là trợ lý ảo FloodSOS.";
    else if (userMsg.includes('công an') || userMsg.includes('113'))       reply = "👮 Số Cảnh sát phản ứng nhanh: 113";
    else if (userMsg.includes('cứu thương') || userMsg.includes('115'))   reply = "🚑 Cấp cứu Y tế: 115";
    else if (userMsg.includes('cứu hỏa') || userMsg.includes('114'))      reply = "🚒 Cứu hỏa: 114";
    else if (userMsg.includes('sos'))                                      reply = "🚨 Hãy bấm nút ĐỎ ngoài màn hình chính để gửi SOS!";

    res.json({ success: true, reply });
};
