// services/csvService.js — CSV sync utilities for Streamlit/Gop_app
const path = require('path');
const fs = require('fs');

// Python đọc file theo đường dẫn tương đối "realtime_outputs/sos_signals.csv"
// => Node ghi thẳng vào đúng file đó để 2 bên ăn khớp.
const SOS_CSV_PATH = path.join(__dirname, '..', '..', '..', 'Gop_app', 'realtime_outputs', 'sos_signals.csv');

const SOS_CSV_HEADERS = [
    "id", "time", "lat", "lon", "note", "status",
    "people_count", "priority_score", "priority_level",
    "flood_prob_near", "time_selected"
];

function csvEscape(value) {
    if (value === null || value === undefined) return "";
    const s = String(value);
    const escaped = s.replace(/"/g, '""');
    if (/[",\r\n]/.test(escaped)) return `"${escaped}"`;
    return escaped;
}

function formatCsvTime(d) {
    const dt = d instanceof Date ? d : new Date(d);
    const pad = (n) => String(n).padStart(2, '0');
    return `${dt.getFullYear()}-${pad(dt.getMonth() + 1)}-${pad(dt.getDate())} ${pad(dt.getHours())}:${pad(dt.getMinutes())}:${pad(dt.getSeconds())}`;
}

function getExistingSosCsvHeader() {
    try {
        if (!fs.existsSync(SOS_CSV_PATH)) return SOS_CSV_HEADERS.slice();
        const text = fs.readFileSync(SOS_CSV_PATH, { encoding: "utf8" });
        const firstLine = text.split(/\r?\n/)[0] || "";
        const cols = firstLine.split(",");
        if (cols.length >= 5) return cols;
    } catch (_) {}
    return SOS_CSV_HEADERS.slice();
}

function ensureSosCsvFile() {
    try {
        const dir = path.dirname(SOS_CSV_PATH);
        fs.mkdirSync(dir, { recursive: true });
        if (!fs.existsSync(SOS_CSV_PATH) || fs.statSync(SOS_CSV_PATH).size === 0) {
            fs.writeFileSync(SOS_CSV_PATH, SOS_CSV_HEADERS.join(",") + "\n", { encoding: "utf8" });
        }
    } catch (e) {
        console.error("ensure csv failed:", e);
    }
}

function appendSosCsvRow(valuesByHeader) {
    try {
        ensureSosCsvFile();
        const header = getExistingSosCsvHeader();
        const line = header.map((h) => csvEscape(valuesByHeader[h] ?? "")).join(",");
        fs.appendFileSync(SOS_CSV_PATH, line + "\n", { encoding: "utf8" });
    } catch (e) {
        console.error("append csv failed:", e);
    }
}

function removeSosFromCsv(csvId) {
    try {
        if (!fs.existsSync(SOS_CSV_PATH)) return;
        const text = fs.readFileSync(SOS_CSV_PATH, { encoding: "utf8" });
        const lines = text.split(/\r?\n/);
        if (lines.length <= 1) return;

        const header = lines[0];
        const body = lines.slice(1).filter((l) => l && l.trim().length > 0);
        const target1 = `${csvId},`;
        const target2 = `"${csvId}",`;
        const filtered = body.filter((line) => !(line.startsWith(target1) || line.startsWith(target2)));
        const content = [header, ...filtered].join("\n") + "\n";
        const tmpPath = `${SOS_CSV_PATH}.tmp_remove`;
        fs.writeFileSync(tmpPath, content, { encoding: "utf8" });
        if (fs.existsSync(SOS_CSV_PATH)) fs.unlinkSync(SOS_CSV_PATH);
        fs.renameSync(tmpPath, SOS_CSV_PATH);
    } catch (e) {
        console.error("remove csv failed:", e);
    }
}

function readSosCsvIdsSet() {
    try {
        if (!fs.existsSync(SOS_CSV_PATH)) return new Set();
        const text = fs.readFileSync(SOS_CSV_PATH, { encoding: "utf8" });
        const lines = text.split(/\r?\n/);
        const ids = new Set();
        for (let i = 1; i < lines.length; i++) {
            const line = lines[i];
            if (!line || line.trim().length === 0) continue;
            const commaIdx = line.indexOf(',');
            if (commaIdx <= 0) continue;
            let id = line.slice(0, commaIdx).trim();
            if (id.startsWith('"') && id.endsWith('"')) {
                id = id.slice(1, -1).replace(/""/g, '"');
            }
            ids.add(id);
        }
        return ids;
    } catch (_) {
        return new Set();
    }
}

module.exports = {
    SOS_CSV_PATH,
    formatCsvTime,
    ensureSosCsvFile,
    appendSosCsvRow,
    removeSosFromCsv,
    readSosCsvIdsSet,
};
