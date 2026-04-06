// controllers/chatController.js — Chatbot response logic
const fs = require('fs');
const path = require('path');

// Load knowledge base
const KNOWLEDGE_BASE_PATH = path.join(__dirname, '../../flood_rescue_chatbot_faq_hotline_only/data/knowledge_base.json');
let knowledgeBase = [];
try {
    if (fs.existsSync(KNOWLEDGE_BASE_PATH)) {
        const rawData = fs.readFileSync(KNOWLEDGE_BASE_PATH, 'utf8');
        knowledgeBase = JSON.parse(rawData);
        console.log(`✅ Đã tải thành công ${knowledgeBase.length} câu hỏi từ knowledge_base.json`);
    } else {
        console.error("❌ Không tìm thấy file knowledge_base.json tại:", KNOWLEDGE_BASE_PATH);
    }
} catch (error) {
    console.error("Lỗi khi load knowledge_base.json:", error);
}

// Load hotlines
const HOTLINES_PATH = path.join(__dirname, '../../flood_rescue_chatbot_faq_hotline_only/data/hotlines.json');
let hotlinesData = { general_emergency: [], provinces: [] };
try {
    if (fs.existsSync(HOTLINES_PATH)) {
        const rawData = fs.readFileSync(HOTLINES_PATH, 'utf8');
        hotlinesData = JSON.parse(rawData);
        console.log(`✅ Đã tải thành công dữ liệu đường dây nóng từ hotlines.json`);
    } else {
        console.error("❌ Không tìm thấy file hotlines.json tại:", HOTLINES_PATH);
    }
} catch (error) {
    console.error("Lỗi khi load hotlines.json:", error);
}

function findHotlineMatch(userMsg) {
    // Tra cứu danh sách tổng đài các tỉnh bằng alias
    if (hotlinesData.provinces) {
        for (const prov of hotlinesData.provinces) {
            for (const alias of prov.aliases || []) {
                if (userMsg.includes(alias.toLowerCase())) {
                    let reply = `📞 **Đơn vị cứu hộ tại ${prov.province}**\n`;
                    for (const contact of prov.contacts || []) {
                        reply += `\n📍 **${contact.name}**\n☎️ Hotline: ${contact.phone}\n📝 ${contact.description}\n`;
                    }
                    reply += `\n(Lưu ý: Bạn đang nhận hỗ trợ từ Cẩm nang PCTT)`;
                    return reply;
                }
            }
        }
    }
    
    // Nếu hỏi hotline nhưng không ghi rõ tỉnh
    if (userMsg.includes('đường dây nóng') || userMsg.includes('hotline') || userMsg.includes('số điện thoại cứu hộ')) {
        let reply = `🚨 **Các đầu số khẩn cấp toàn quốc:**\n`;
        for (const em of hotlinesData.general_emergency || []) {
            reply += `\n☎️ **${em.phone}** - ${em.name}\n${em.description}\n`;
        }
        reply += `\nNếu bạn cần số liên hệ của một tỉnh cụ thể, hãy nhập tên tỉnh (vd: Đà Nẵng, Nghệ An...).`;
        return reply;
    }

    return null;
}

function formatItem(item) {
    let text = item.answer || "";
    
    if (item.immediate_actions && item.immediate_actions.length > 0) {
        text += "\n\n🚑 Hành động khẩn cấp:\n" + item.immediate_actions.map(act => "- " + act).join('\n');
    }
    
    if (item.dont_do && item.dont_do.length > 0) {
        text += "\n\n🚫 Tuyệt đối không làm:\n" + item.dont_do.map(act => "- " + act).join('\n');
    }
    
    if (item.escalate_if && item.escalate_if.length > 0) {
        text += "\n\n⚠️ Gọi cấp cứu ngay nếu có biểu hiện:\n" + item.escalate_if.map(act => "- " + act).join('\n');
    }
    
    text += "\n\n(Lưu ý: Bạn đang nhận hỗ trợ từ Cẩm nang PCTT)";
    return text;
}

function findBestMatch(userMsg) {
    const minMatchLength = 4;
    // Basic exact phrase match
    for (const item of knowledgeBase) {
        if (!item.question_variations) continue;
        for (const variation of item.question_variations) {
            const q = variation.toLowerCase();
            if (userMsg.includes(q) || (q.includes(userMsg) && userMsg.length >= minMatchLength)) {
                return formatItem(item);
            }
        }
    }
    
    // Token-based keyword match as fallback
    const tokens = userMsg.split(' ').filter(t => t.length > 2);
    let bestMatch = null;
    let maxScore = 0;
    
    for (const item of knowledgeBase) {
        if (!item.question_variations) continue;
        for (const variation of item.question_variations) {
            const q = variation.toLowerCase();
            let score = 0;
            for (const token of tokens) {
                if (q.includes(token)) score++;
            }
            if (score > maxScore) {
                maxScore = score;
                bestMatch = formatItem(item);
            }
        }
    }
    
    // Require at least 2 matching words, or 1 if the user only typed 1 or 2 words
    if (maxScore >= 2 || (maxScore >= 1 && tokens.length <= 2)) {
        return bestMatch;
    }

    return null;
}

exports.chat = (req, res) => {
    const userMsg = req.body.message ? req.body.message.toLowerCase() : "";
    let reply = "Xin lỗi, tôi chưa hiểu ý bạn. Vui lòng thử hỏi về các tình huống khẩn cấp (như mất điện, sơ tán, sơ cứu, rắn cắn...).";

    // 1. Tìm trong hotlines trước (tra cứu theo tỉnh, đầu số khẩn cấp)
    const hotlineReply = findHotlineMatch(userMsg);
    if (hotlineReply) {
        return res.json({ success: true, reply: hotlineReply });
    }

    // 2. Tìm trong knowledge base (FAQ, playbook sơ cứu, tình huống khẩn cấp)
    const kbReply = findBestMatch(userMsg);
    if (kbReply) {
        return res.json({ success: true, reply: kbReply });
    }

    // 3. Fallback: các câu trả lời nhanh cho từ khóa đơn giản
    if (userMsg.includes('xin chào') || userMsg === 'hi' || userMsg === 'hello' || userMsg === 'chào') {
        reply = "Chào bạn! Tôi là trợ lý ảo FloodSOS. Hãy hỏi tôi về các tình huống khẩn cấp, sơ cứu, hoặc số hotline cứu hộ theo tỉnh.";
    } else if (userMsg.includes('113')) {
        reply = "👮 Số Cảnh sát phản ứng nhanh: 113";
    } else if (userMsg.includes('115')) {
        reply = "🚑 Cấp cứu Y tế: 115";
    } else if (userMsg.includes('114')) {
        reply = "🚒 Cứu hỏa: 114";
    } else if (userMsg === 'sos' || userMsg.includes('khẩn cấp')) {
        reply = "🚨 Hãy bấm nút ĐỎ ngoài màn hình chính để gửi vị trí SOS ngay lập tức!";
    }

    res.json({ success: true, reply });
};
