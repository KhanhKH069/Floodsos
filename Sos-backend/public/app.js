// Cấu hình Map
const map = L.map('map', {
    center: [16.4637, 107.5908], // Hue, Vietnam center
    zoom: 13,
    zoomControl: false // Chúng ta dùng style custom hoặc lược bỏ
});

// Tile layer Dark Mode (CartoDB Dark Matter)
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/">CARTO</a>',
    maxZoom: 19
}).addTo(map);

// Socket.io
const socket = io();

// State
let sosAlerts = [];
let drones = [];
let rescueTeams = [];
let predictiveReports = [];
let shelters = [];
let mapMarkers = {}; // Để quản lý xóa/thêm marker
let selectedSOS = null;

// Custom Icons
const createDivIcon = (type, customClass = '') => {
    let html = '';
    if (type === 'sos') html = `<div class="sos-marker ${customClass}"><i class="fa-solid fa-exclamation"></i></div>`;
    if (type === 'drone') html = `<div style="color:var(--accent-green); text-shadow:0 0 10px #00ff88; font-size:24px"><i class="fa-solid fa-helicopter"></i></div>`;
    if (type === 'team') html = `<div style="color:var(--accent-cyan); text-shadow:0 0 10px #00e5ff; font-size:24px"><i class="fa-solid fa-truck-medical"></i></div>`;
    if (type === 'shelter') html = `<div style="color:#ffee00; text-shadow:0 0 10px #ffee00; font-size:24px"><i class="fa-solid fa-house-medical"></i></div>`;
    if (type === 'predictive') html = `<div style="background:rgba(0,210,255,0.4); width:15px; height:15px; border-radius:50%; box-shadow: 0 0 10px rgba(0,210,255,0.6)"></div>`;

    return L.divIcon({ className: 'custom-leaflet-icon', html, iconSize: [30, 30], iconAnchor: [15, 15], popupAnchor: [0, -15] });
};

// Fetch Data
const fetchData = async () => {
    try {
        const [sosRes, droneRes, teamRes, predictRes, shelterRes] = await Promise.all([
            fetch('/api/sos').then(r => r.json()),
            fetch('/api/drones').then(r => r.json()),
            fetch('/api/teams').then(r => r.json()),
            fetch('/api/predict_flood').then(r => r.json()),
            fetch('/api/shelters').then(r => r.json())
        ]);
        
        sosAlerts = sosRes;
        drones = droneRes;
        rescueTeams = teamRes;
        predictiveReports = predictRes;
        shelters = shelterRes;
        
        updateStats();
        renderMapMarkers();
        updateDispatchTeamsDropdown();
    } catch (error) {
        console.error("Error fetching data:", error);
    }
};

// UI Stats
const updateStats = () => {
    document.getElementById('stat-sos').innerText = sosAlerts.filter(s => s.status !== 'dispatched').length;
    document.getElementById('stat-drones').innerText = drones.length;
    document.getElementById('stat-teams').innerText = rescueTeams.length;
};

const updateDispatchTeamsDropdown = () => {
    const selector = document.getElementById('team-selector');
    selector.innerHTML = '';
    const idleTeams = rescueTeams.filter(t => t.status === 'idle');
    if (idleTeams.length === 0) {
        selector.innerHTML = '<option disabled selected>No idle teams available</option>';
        document.getElementById('btn-confirm-dispatch').disabled = true;
        document.getElementById('btn-confirm-dispatch').style.opacity = '0.5';
    } else {
        document.getElementById('btn-confirm-dispatch').disabled = false;
        document.getElementById('btn-confirm-dispatch').style.opacity = '1';
        idleTeams.forEach(t => {
            const opt = document.createElement('option');
            opt.value = t.id;
            opt.innerText = `${t.name} - ${t.vehicle}`;
            selector.appendChild(opt);
        });
    }
};

// Map Rendering
const clearMarkers = () => {
    Object.values(mapMarkers).forEach(m => map.removeLayer(m));
    mapMarkers = {};
};

const renderMapMarkers = () => {
    clearMarkers();

    // Render Predictive (as heat/dots)
    // Only render a subset to prevent major lag, or just all since Leaflet can handle ~500 simple divIcons
    predictiveReports.forEach((p, idx) => {
        const marker = L.marker([p.lat, p.lon], { icon: createDivIcon('predictive'), interactive: false }).addTo(map);
        mapMarkers[`pred_${idx}`] = marker;
    });

    // Render Shelters
    shelters.forEach(s => {
        const marker = L.marker([s.lat, s.lon], { icon: createDivIcon('shelter'), zIndexOffset: 750 }).addTo(map);
        marker.bindPopup(`<b>${s.name}</b><br>Sức chứa: ${s.current}/${s.capacity} (Trạm trú ẩn)`);
        mapMarkers[`shelter_${s.id}`] = marker;
    });

    // Render Teams
    rescueTeams.forEach(t => {
        const marker = L.marker([t.lat, t.lon], { icon: createDivIcon('team'), zIndexOffset: 800 }).addTo(map);
        marker.bindPopup(`<b>${t.name}</b><br>Trạng thái: ${t.status.toUpperCase()}<br>Phương tiện: ${t.vehicle}`);
        mapMarkers[`team_${t.id}`] = marker;
    });

    // Render Drones
    drones.forEach(d => {
        const marker = L.marker([d.lat, d.lon], { icon: createDivIcon('drone'), zIndexOffset: 900 }).addTo(map);
        marker.bindPopup(`<b>${d.name}</b><br>Pin: ${d.battery}%<br>Trạng thái: ${d.status.toUpperCase()}<br><button class="btn-live-drone" onclick="openDroneVideo('${d.id}')" style="background:#00ff88; color:#000; padding:5px 10px; border-radius:5px; border:none; margin-top:10px; cursor:pointer; width:100%; font-weight:bold"><i class="fa-solid fa-video"></i> Xem Camera</button>`);
        mapMarkers[`drone_${d.id}`] = marker;
    });

    // Render SOS
    sosAlerts.forEach(s => {
        let sc = s.status;
        if (s.status === 'dispatched') sc = 'dispatched'; // green
        
        const marker = L.marker([s.latitude, s.longitude], { icon: createDivIcon('sos', sc), zIndexOffset: 1000 }).addTo(map);
        marker.on('click', () => {
            openDispatchPanel(s);
            map.flyTo([s.latitude, s.longitude], 16, { duration: 1.5 });
        });
        mapMarkers[`sos_${s.id}`] = marker;
    });
};

// Dispatch Interaction
const openDispatchPanel = (sos) => {
    selectedSOS = sos;
    const panel = document.getElementById('dispatch-panel');
    const details = document.getElementById('dispatch-details');
    const actions = document.getElementById('dispatch-actions-div');

    panel.classList.remove('hidden');
    
    let html = `<strong>Nạn nhân:</strong> ${sos.name || 'Không rõ'} <br>
                <strong>SĐT:</strong> ${sos.phone || 'N/A'} <br>
                <strong>Mức nước:</strong> ${sos.waterLevel || 'N/A'}<br>
                <strong>Nhóm:</strong> ${sos.peopleCount || '1'} người<br>
                <strong>Lời nhắn:</strong> <i>"${sos.message || ''}"</i><br>
                <strong>Trạng thái:</strong> <span style="color:${sos.status==='dispatched'?'var(--accent-green)':'var(--accent-red)'}; text-transform:uppercase;">${sos.status}</span>`;
    
    details.innerHTML = html;

    if (sos.status !== 'dispatched') {
        actions.classList.remove('hidden');
    } else {
        actions.classList.add('hidden');
        details.innerHTML += `<br><br><div style="background:rgba(0,255,136,0.1); padding:10px; border:1px solid var(--accent-green); border-radius:8px; color:var(--accent-green)"><i class="fa-solid fa-check-circle"></i> Đã điều động đội cứu hộ.</div>`;
    }
};

document.getElementById('btn-cancel-dispatch').addEventListener('click', () => {
    document.getElementById('dispatch-panel').classList.add('hidden');
    selectedSOS = null;
});

document.getElementById('btn-confirm-dispatch').addEventListener('click', async () => {
    if (!selectedSOS) return;
    const teamId = document.getElementById('team-selector').value;
    
    document.getElementById('btn-confirm-dispatch').innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> Deploying...`;
    
    const res = await fetch(`/api/sos/${selectedSOS.id}/dispatch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ teamId })
    });

    if (res.ok) {
        document.getElementById('dispatch-panel').classList.add('hidden');
        // socket will trigger refetching
    }
    document.getElementById('btn-confirm-dispatch').innerHTML = `<i class="fa-solid fa-bolt"></i> Deploy`;
});

// Drone Modal Logic
window.openDroneVideo = (droneId) => {
    const drone = drones.find(d => d.id === droneId);
    if (!drone) return;
    
    document.getElementById('drone-name-modal').innerText = drone.name;
    document.getElementById('drone-bat').innerText = drone.battery;
    document.getElementById('drone-lat').innerText = drone.lat.toFixed(5);
    document.getElementById('drone-lon').innerText = drone.lon.toFixed(5);
    
    document.getElementById('drone-modal').classList.remove('hidden');
};

document.getElementById('close-modal').addEventListener('click', () => {
    document.getElementById('drone-modal').classList.add('hidden');
});
document.querySelector('.modal-backdrop').addEventListener('click', () => {
    document.getElementById('drone-modal').classList.add('hidden');
});

// Real-time Events
socket.on('sos_updated', () => fetchData());
socket.on('teams_updated', () => fetchData());
socket.on('drones_updated', () => fetchData());
socket.on('report_updated', () => fetchData());

// Init
fetchData();
