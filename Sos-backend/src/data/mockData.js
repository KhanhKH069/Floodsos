const DRONE_BASES = {
    'DR-01': { lat: 16.4690, lon: 107.5760 }, // Đại Nội Huế
    'DR-02': { lat: 16.4735, lon: 107.6072 }, // Phường Vĩ Dạ
    'DR-03': { lat: 16.4526, lon: 107.5912 }  // An Cựu
};

let GLOBAL_DRONES = [
    { id: 'DR-01', name: 'Drone Đại Nội', lat: 16.4690, lon: 107.5760, status: 'idle', battery: 95, targetId: null },
    { id: 'DR-02', name: 'Drone Vĩ Dạ', lat: 16.4735, lon: 107.6072, status: 'idle', battery: 88, targetId: null },
    { id: 'DR-03', name: 'Drone An Cựu', lat: 16.4526, lon: 107.5912, status: 'idle', battery: 72, targetId: null }
];

let RESCUE_TEAMS = [
    { id: 'T-01', name: 'Đội Cứu Hộ Cơ Động (Q.1)', lat: 16.4600, lon: 107.5800, status: 'idle', targetId: null, vehicle: 'Cano' },
    { id: 'T-02', name: 'Đội Lực Lượng Xung Kích (Q.2)', lat: 16.4700, lon: 107.5900, status: 'idle', targetId: null, vehicle: 'Thuyền Nhựa' },
    { id: 'T-03', name: 'Đội Xuồng Cao Su (Q.3)', lat: 16.4500, lon: 107.6000, status: 'idle', targetId: null, vehicle: 'Xuồng Cao Su' }
];

let SHELTERS = [
    { id: 'S-01', name: 'Trường Quốc Học Huế', lat: 16.4633, lon: 107.5861, capacity: 500, current: 120 },
    { id: 'S-02', name: 'Nhà thi đấu Thừa Thiên Huế', lat: 16.4678, lon: 107.5760, capacity: 1000, current: 400 },
    { id: 'S-03', name: 'Nhà Văn LĐ Tỉnh', lat: 16.4740, lon: 107.5920, capacity: 300, current: 80 }
];

module.exports = { DRONE_BASES, GLOBAL_DRONES, RESCUE_TEAMS, SHELTERS };
