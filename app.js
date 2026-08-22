/* ==========================================================================
   TITEN IoT Disaster Warning System - Interactive Application Engine
   Features: Dual Hazard Sensing (Landslide + Karhutla), Flutter Light UX,
             Spatial GIS Canvas, Consensus Graph, Telemetry Charts, Security PIN
   ========================================================================== */

// --- Global Application State ---
const state = {
  activeTab: 'status', // 'status' | 'map' | 'logs' | 'alerts'
  currentThreatLevel: 'aman', // 'aman' | 'waspada_longsor' | 'waspada_karhutla' | 'siaga' | 'awas_longsor' | 'awas_karhutla'
  activeMapLayers: {
    contour: true,
    heatmap: true,
    nodes: true
  },
  activeChartMetric: 'tilt', // 'tilt' | 'soil' | 'temp' | 'humidity'
  selectedNode: 'Node 01',
  pendingAction: null,
  
  // Nodes telemetry baseline data
  nodes: {
    'Node 01': {
      id: '01',
      name: 'Node 01 (Puncak Lereng & Hutan)',
      x: 180,
      y: 120,
      health: 'SEHAT',
      battery: 94,
      voltage: 3.95,
      tilt: 1.2,
      deltaTilt: 0.1,
      soil: 65,
      temp: 26.5,
      humidity: 72,
      fdi: 0.12,
      svi: 0.18,
      rssi: -84,
      snr: 9.5,
      powerMode: 'SoPoWake Deep Sleep',
      status: 'aman'
    },
    'Node 02': {
      id: '02',
      name: 'Node 02 (Tengah Lereng)',
      x: 320,
      y: 220,
      health: 'SEHAT',
      battery: 91,
      voltage: 3.91,
      tilt: 1.4,
      deltaTilt: 0.2,
      soil: 68,
      temp: 26.8,
      humidity: 70,
      fdi: 0.14,
      svi: 0.20,
      rssi: -88,
      snr: 8.8,
      powerMode: 'SoPoWake Deep Sleep',
      status: 'aman'
    },
    'Node 03': {
      id: '03',
      name: 'Node 03 (Kaki Lereng)',
      x: 440,
      y: 320,
      health: 'SEHAT',
      battery: 96,
      voltage: 4.02,
      tilt: 0.9,
      deltaTilt: 0.05,
      soil: 62,
      temp: 26.1,
      humidity: 75,
      fdi: 0.10,
      svi: 0.15,
      rssi: -81,
      snr: 10.2,
      powerMode: 'SoPoWake Deep Sleep',
      status: 'aman'
    }
  },

  gateway: {
    name: 'LoRa Gateway (Pos Desa)',
    x: 100,
    y: 370
  }
};

// Canvas & Chart References
let mapCanvas, mapCtx;
let consensusCanvas, consensusCtx;
let mainChartInstance;
let mapAnimId, consensusAnimId;

// Initialize Application on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
  initClock();
  initSpatialMap();
  initConsensusGraph();
  initTelemetryChart();
  triggerSimulation('aman');
});

// ==========================================================================
// 1. Navigation & Viewport Mode Controller
// ==========================================================================
function switchTab(tabName) {
  state.activeTab = tabName;
  
  // Update Tab Screens visibility
  document.querySelectorAll('.tab-screen').forEach(screen => {
    screen.classList.remove('active');
  });
  
  const targetScreen = document.getElementById(`tab${capitalize(tabName)}`);
  if (targetScreen) targetScreen.classList.add('active');

  // Update Nav Items active pill
  document.querySelectorAll('.nav-item').forEach(nav => {
    nav.classList.remove('active');
  });

  const targetNav = document.getElementById(`nav${capitalize(tabName)}`);
  if (targetNav) targetNav.classList.add('active');

  // Trigger canvas resize re-draws when switching tabs
  setTimeout(() => {
    resizeCanvases();
  }, 50);
}

function toggleMobileFrameView() {
  const shell = document.getElementById('appShell');
  shell.classList.toggle('full-view');
  setTimeout(resizeCanvases, 100);
}

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Live Clock for Header Bar
function initClock() {
  function updateTime() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('id-ID', { hour12: false });
    const mobileClock = document.getElementById('mobileClock');
    const lastUpdate = document.getElementById('lastUpdateTime');
    
    if (mobileClock) mobileClock.textContent = timeStr.substring(0, 5);
    if (lastUpdate) lastUpdate.textContent = `${timeStr} WIB`;
  }
  setInterval(updateTime, 1000);
  updateTime();
}

// ==========================================================================
// 2. Spatial GIS Map Canvas Engine (Light Mode Topography)
// ==========================================================================
function initSpatialMap() {
  mapCanvas = document.getElementById('mapCanvas');
  if (!mapCanvas) return;
  mapCtx = mapCanvas.getContext('2d');

  resizeMapCanvas();
  window.addEventListener('resize', resizeMapCanvas);

  // Click Handler for Map Nodes
  mapCanvas.addEventListener('click', (e) => {
    const rect = mapCanvas.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;

    const scaleX = mapCanvas.width / 500;
    const scaleY = mapCanvas.height / 380;

    let clicked = false;
    Object.entries(state.nodes).forEach(([key, node]) => {
      const nx = node.x * scaleX;
      const ny = node.y * scaleY;
      const dist = Math.hypot(clickX - nx, clickY - ny);
      if (dist < 25) {
        showNodePopup(key);
        clicked = true;
      }
    });

    if (!clicked) {
      const popup = document.getElementById('nodePopup');
      if (popup) popup.classList.add('hidden');
    }
  });

  let pulsePhase = 0;
  function renderMap() {
    pulsePhase += 0.05;
    drawMapCanvas(pulsePhase);
    mapAnimId = requestAnimationFrame(renderMap);
  }
  renderMap();
}

function resizeMapCanvas() {
  if (!mapCanvas) return;
  const parent = mapCanvas.parentElement;
  mapCanvas.width = parent.clientWidth;
  mapCanvas.height = parent.clientHeight;
}

function drawMapCanvas(pulse) {
  if (!mapCtx) return;
  const w = mapCanvas.width;
  const h = mapCanvas.height;
  const sx = w / 500;
  const sy = h / 380;

  // 1. Clear background (Slate 100 / Light Grid)
  mapCtx.fillStyle = '#F1F5F9';
  mapCtx.fillRect(0, 0, w, h);

  // 2. Tactical Grid Lines
  mapCtx.strokeStyle = 'rgba(203, 213, 225, 0.4)';
  mapCtx.lineWidth = 1;
  const gridSize = 35 * sx;
  for (let x = 0; x < w; x += gridSize) {
    mapCtx.beginPath();
    mapCtx.moveTo(x, 0);
    mapCtx.lineTo(x, h);
    mapCtx.stroke();
  }
  for (let y = 0; y < h; y += gridSize) {
    mapCtx.beginPath();
    mapCtx.moveTo(0, y);
    mapCtx.lineTo(w, y);
    mapCtx.stroke();
  }

  // 3. Draw Topo Contour Lines (if active)
  if (state.activeMapLayers.contour) {
    drawContourLines(sx, sy);
  }

  // 4. Draw Heatmap Gradient Overlay (if active)
  if (state.activeMapLayers.heatmap) {
    drawHeatmapOverlay(sx, sy);
  }

  // 5. Draw LoRa Wireless Links between Nodes and Gateway
  mapCtx.setLineDash([4, 4]);
  mapCtx.strokeStyle = 'rgba(2, 132, 199, 0.5)';
  mapCtx.lineWidth = 1.5;

  const gwX = state.gateway.x * sx;
  const gwY = state.gateway.y * sy;

  Object.values(state.nodes).forEach(n => {
    const nx = n.x * sx;
    const ny = n.y * sy;
    mapCtx.beginPath();
    mapCtx.moveTo(gwX, gwY);
    mapCtx.lineTo(nx, ny);
    mapCtx.stroke();
  });
  mapCtx.setLineDash([]);

  // Gateway Icon
  mapCtx.fillStyle = '#0284C7';
  mapCtx.beginPath();
  mapCtx.arc(gwX, gwY, 7, 0, Math.PI * 2);
  mapCtx.fill();
  mapCtx.strokeStyle = '#FFFFFF';
  mapCtx.lineWidth = 2;
  mapCtx.stroke();

  mapCtx.fillStyle = '#64748B';
  mapCtx.font = 'bold 9px "JetBrains Mono"';
  mapCtx.fillText('Gateway Pos Desa', gwX - 35, gwY + 18);

  // 6. Draw Sensor Nodes (if active)
  if (state.activeMapLayers.nodes) {
    Object.values(state.nodes).forEach(n => {
      const nx = n.x * sx;
      const ny = n.y * sy;

      let nodeColor = '#10B981'; // Aman
      if (n.status === 'waspada_longsor') nodeColor = '#F59E0B';
      if (n.status === 'waspada_karhutla') nodeColor = '#EA580C';
      if (n.status === 'siaga') nodeColor = '#F97316';
      if (n.status === 'awas_longsor') nodeColor = '#EF4444';
      if (n.status === 'awas_karhutla') nodeColor = '#DC2626';

      // Outer Pulse Ring
      const pulseR = 10 + Math.sin(pulse * 3) * 5;
      mapCtx.strokeStyle = nodeColor;
      mapCtx.lineWidth = 1.5;
      mapCtx.beginPath();
      mapCtx.arc(nx, ny, pulseR, 0, Math.PI * 2);
      mapCtx.stroke();

      // Core Circle
      mapCtx.fillStyle = nodeColor;
      mapCtx.beginPath();
      mapCtx.arc(nx, ny, 7, 0, Math.PI * 2);
      mapCtx.fill();
      mapCtx.strokeStyle = '#FFFFFF';
      mapCtx.lineWidth = 2;
      mapCtx.stroke();

      // Node Label
      mapCtx.fillStyle = '#0F172A';
      mapCtx.font = 'bold 10px "Manrope"';
      mapCtx.fillText(`Node ${n.id}`, nx - 16, ny - 12);
      mapCtx.fillStyle = '#64748B';
      mapCtx.font = '9px "JetBrains Mono"';
      mapCtx.fillText(`T:${n.temp}°C | Tilt:${n.tilt}°`, nx - 28, ny + 18);
    });
  }
}

function drawContourLines(sx, sy) {
  const contours = [
    { elev: '450m (Puncak Hutan)', color: 'rgba(2, 132, 199, 0.3)', path: [[60, 90], [180, 100], [320, 130], [460, 160]] },
    { elev: '420m', color: 'rgba(2, 132, 199, 0.2)', path: [[40, 160], [200, 170], [340, 200], [470, 230]] },
    { elev: '390m (Tengah)', color: 'rgba(2, 132, 199, 0.15)', path: [[30, 230], [220, 240], [360, 270], [480, 300]] }
  ];

  contours.forEach(c => {
    mapCtx.strokeStyle = c.color;
    mapCtx.lineWidth = 1.5;
    mapCtx.beginPath();
    c.path.forEach((pt, idx) => {
      const px = pt[0] * sx;
      const py = pt[1] * sy;
      if (idx === 0) mapCtx.moveTo(px, py);
      else mapCtx.lineTo(px, py);
    });
    mapCtx.stroke();

    const lblPt = c.path[0];
    mapCtx.fillStyle = 'rgba(2, 132, 199, 0.6)';
    mapCtx.font = '9px "JetBrains Mono"';
    mapCtx.fillText(c.elev, lblPt[0] * sx + 5, lblPt[1] * sy - 4);
  });
}

function drawHeatmapOverlay(sx, sy) {
  const gradient = mapCtx.createRadialGradient(260 * sx, 200 * sy, 20 * sx, 260 * sx, 200 * sy, 160 * sx);
  
  if (state.currentThreatLevel === 'awas_karhutla') {
    gradient.addColorStop(0, 'rgba(220, 38, 38, 0.4)');
    gradient.addColorStop(0.5, 'rgba(234, 88, 12, 0.25)');
    gradient.addColorStop(1, 'transparent');
  } else if (state.currentThreatLevel === 'awas_longsor') {
    gradient.addColorStop(0, 'rgba(239, 68, 68, 0.4)');
    gradient.addColorStop(0.5, 'rgba(249, 115, 22, 0.2)');
    gradient.addColorStop(1, 'transparent');
  } else if (state.currentThreatLevel === 'waspada_karhutla') {
    gradient.addColorStop(0, 'rgba(234, 88, 12, 0.3)');
    gradient.addColorStop(1, 'transparent');
  } else if (state.currentThreatLevel === 'waspada_longsor') {
    gradient.addColorStop(0, 'rgba(245, 158, 11, 0.3)');
    gradient.addColorStop(1, 'transparent');
  } else {
    gradient.addColorStop(0, 'rgba(16, 185, 129, 0.12)');
    gradient.addColorStop(1, 'transparent');
  }

  mapCtx.fillStyle = gradient;
  mapCtx.beginPath();
  mapCtx.arc(260 * sx, 200 * sy, 160 * sx, 0, Math.PI * 2);
  mapCtx.fill();
}

function toggleMapLayer(layer) {
  state.activeMapLayers[layer] = !state.activeMapLayers[layer];
  const btn = document.getElementById(`toggle${capitalize(layer)}`);
  if (btn) {
    btn.classList.toggle('active', state.activeMapLayers[layer]);
  }
}

function showNodePopup(nodeKey) {
  const n = state.nodes[nodeKey];
  if (!n) return;
  state.selectedNode = nodeKey;

  const popup = document.getElementById('nodePopup');
  if (!popup) return;

  document.getElementById('popupNodeName').innerText = n.name;
  document.getElementById('popupNodeHealth').innerText = `${n.health} / ${n.status.toUpperCase()}`;
  document.getElementById('popupNodeBat').innerText = `${n.battery}% (${n.voltage}V)`;
  document.getElementById('popupNodeTilt').innerText = `${n.tilt}°`;
  document.getElementById('popupNodeTemp').innerText = `${n.temp}°C (${n.humidity}%)`;
  document.getElementById('popupNodeLora').innerText = `${n.rssi} dBm (SNR ${n.snr})`;
  document.getElementById('popupNodePower').innerText = n.powerMode;

  const dot = document.getElementById('popupNodeDot');
  if (dot) {
    let color = '#10B981';
    if (n.status.includes('waspada')) color = '#F59E0B';
    if (n.status.includes('karhutla')) color = '#EA580C';
    if (n.status === 'siaga') color = '#F97316';
    if (n.status === 'awas_longsor') color = '#EF4444';
    if (n.status === 'awas_karhutla') color = '#DC2626';
    dot.style.backgroundColor = color;
  }

  popup.classList.remove('hidden');
}

// ==========================================================================
// 3. Multi-Node Consensus Visualizer Graph
// ==========================================================================
function initConsensusGraph() {
  consensusCanvas = document.getElementById('consensusCanvas');
  if (!consensusCanvas) return;
  consensusCtx = consensusCanvas.getContext('2d');

  resizeConsensusCanvas();
  window.addEventListener('resize', resizeConsensusCanvas);

  let particlePhase = 0;
  function renderConsensus() {
    particlePhase += 0.04;
    drawConsensusCanvas(particlePhase);
    consensusAnimId = requestAnimationFrame(renderConsensus);
  }
  renderConsensus();
}

function resizeConsensusCanvas() {
  if (!consensusCanvas) return;
  const parent = consensusCanvas.parentElement;
  consensusCanvas.width = parent.clientWidth;
  consensusCanvas.height = parent.clientHeight;
}

function drawConsensusCanvas(phase) {
  if (!consensusCtx) return;
  const w = consensusCanvas.width;
  const h = consensusCanvas.height;

  consensusCtx.clearRect(0, 0, w, h);

  const graphNodes = [
    { id: '01', x: w * 0.25, y: h * 0.45, label: 'Node 01 (Puncak)' },
    { id: '02', x: w * 0.50, y: h * 0.45, label: 'Node 02 (Tengah)' },
    { id: '03', x: w * 0.75, y: h * 0.45, label: 'Node 03 (Kaki)' }
  ];

  let linkColor = '#10B981';
  let badgeText = '<i class="fa-solid fa-check-double"></i> 3/3 Node Sepakat: Tidak Ada Anomali Geologis Maupun Panas';
  let badgeStyle = 'background: #ECFDF5; color: #10B981; border: 1px solid #A7F3D0;';

  if (state.currentThreatLevel === 'waspada_longsor') {
    linkColor = '#F59E0B';
    badgeText = '<i class="fa-solid fa-triangle-exclamation"></i> 1/3 Node Mendeteksi Pergerakan Tanah (Anomali Lokal)';
    badgeStyle = 'background: #FFFBEB; color: #F59E0B; border: 1px solid #FDE68A;';
  } else if (state.currentThreatLevel === 'waspada_karhutla') {
    linkColor = '#EA580C';
    badgeText = '<i class="fa-solid fa-fire"></i> 1/3 Node Mendeteksi Lonjakan Panas Udara (Waspada Karhutla)';
    badgeStyle = 'background: #FFEDD5; color: #EA580C; border: 1px solid #FED7AA;';
  } else if (state.currentThreatLevel === 'siaga') {
    linkColor = '#F97316';
    badgeText = '<i class="fa-solid fa-bell"></i> 2/3 Node Terkonfirmasi Mengalami Anomali (SIAGA BENCANA)';
    badgeStyle = 'background: #FFEDD5; color: #F97316; border: 1px solid #FDBA74;';
  } else if (state.currentThreatLevel === 'awas_longsor') {
    linkColor = '#EF4444';
    badgeText = '<i class="fa-solid fa-circle-exclamation fa-beat"></i> 3/3 NODE KONSENSUS BAHAYA LONGSOR (EVAKUASI!)';
    badgeStyle = 'background: #FEF2F2; color: #EF4444; border: 1px solid #FCA5A5;';
  } else if (state.currentThreatLevel === 'awas_karhutla') {
    linkColor = '#DC2626';
    badgeText = '<i class="fa-solid fa-fire-flame-curved fa-beat"></i> 3/3 NODE KONSENSUS BAHAYA KEBAKARAN HUTAN!';
    badgeStyle = 'background: #FEF2F2; color: #DC2626; border: 1px solid #FCA5A5;';
  }

  const badgeEl = document.getElementById('consensusBadge');
  if (badgeEl) {
    badgeEl.innerHTML = badgeText;
    badgeEl.style.cssText = badgeStyle;
  }

  // Draw Mesh Edges
  const links = [[0, 1], [1, 2], [0, 2]];
  links.forEach(([i, j]) => {
    const n1 = graphNodes[i];
    const n2 = graphNodes[j];

    consensusCtx.strokeStyle = linkColor;
    consensusCtx.lineWidth = 2;
    consensusCtx.beginPath();
    consensusCtx.moveTo(n1.x, n1.y);
    consensusCtx.lineTo(n2.x, n2.y);
    consensusCtx.stroke();

    // Data Packet Particle Animation
    const prog = (phase + i * 0.4) % 1;
    const px = n1.x + (n2.x - n1.x) * prog;
    const py = n1.y + (n2.y - n1.y) * prog;

    consensusCtx.fillStyle = '#0284C7';
    consensusCtx.beginPath();
    consensusCtx.arc(px, py, 3.5, 0, Math.PI * 2);
    consensusCtx.fill();
  });

  // Draw Graph Nodes
  graphNodes.forEach((n) => {
    const nodeObj = state.nodes[`Node ${n.id}`];
    let nColor = '#10B981';
    if (nodeObj.status.includes('waspada')) nColor = '#F59E0B';
    if (nodeObj.status.includes('karhutla')) nColor = '#EA580C';
    if (nodeObj.status === 'siaga') nColor = '#F97316';
    if (nodeObj.status === 'awas_longsor') nColor = '#EF4444';
    if (nodeObj.status === 'awas_karhutla') nColor = '#DC2626';

    consensusCtx.fillStyle = nColor;
    consensusCtx.beginPath();
    consensusCtx.arc(n.x, n.y, 9, 0, Math.PI * 2);
    consensusCtx.fill();
    consensusCtx.strokeStyle = '#FFFFFF';
    consensusCtx.lineWidth = 2;
    consensusCtx.stroke();

    consensusCtx.fillStyle = '#0F172A';
    consensusCtx.font = 'bold 9px "Manrope"';
    consensusCtx.fillText(n.label, n.x - 26, n.y + 20);
  });
}

// ==========================================================================
// 4. Real-time Telemetry Chart Engine (Chart.js Light Theme)
// ==========================================================================
function initTelemetryChart() {
  const ctx = document.getElementById('mainTelemetryChart');
  if (!ctx) return;

  const timeLabels = ['14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '19:42'];

  mainChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: timeLabels,
      datasets: [{
        label: 'Sudut Kemiringan (°)',
        data: [1.1, 1.2, 1.1, 1.3, 1.2, 1.2, 1.2],
        borderColor: '#0284C7',
        backgroundColor: 'rgba(2, 132, 199, 0.1)',
        fill: true,
        tension: 0.3,
        borderWidth: 2,
        pointRadius: 3,
        pointBackgroundColor: '#0284C7'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: {
          grid: { color: 'rgba(226, 232, 240, 0.6)' },
          ticks: { color: '#64748B', font: { size: 9, family: 'JetBrains Mono' } }
        },
        y: {
          grid: { color: 'rgba(226, 232, 240, 0.6)' },
          ticks: { color: '#64748B', font: { size: 9, family: 'JetBrains Mono' } }
        }
      }
    }
  });
}

function switchChartTab(metric) {
  state.activeChartMetric = metric;

  document.querySelectorAll('.chart-toggle-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  event.target.classList.add('active');

  updateChartData();
}

function updateChartData() {
  if (!mainChartInstance) return;

  const metric = state.activeChartMetric;
  let dataset = [];
  let label = '';
  let color = '#0284C7';

  if (metric === 'tilt') {
    label = 'Sudut Kemiringan (°)';
    color = '#0284C7';
    if (state.currentThreatLevel === 'awas_longsor') dataset = [1.1, 2.0, 4.5, 8.1, 11.4, 13.8, 15.2];
    else if (state.currentThreatLevel === 'waspada_longsor') dataset = [1.1, 1.2, 1.5, 2.1, 2.9, 3.4, 3.8];
    else dataset = [1.1, 1.2, 1.1, 1.3, 1.2, 1.2, 1.2];
  } else if (metric === 'soil') {
    label = 'Kelembapan Tanah (%)';
    color = '#3B82F6';
    if (state.currentThreatLevel === 'awas_longsor') dataset = [60, 70, 80, 88, 92, 95, 96];
    else dataset = [60, 62, 63, 64, 65, 65, 65];
  } else if (metric === 'temp') {
    label = 'Suhu Udara DHT22 (°C)';
    color = '#EA580C';
    if (state.currentThreatLevel === 'awas_karhutla') dataset = [26.5, 29.0, 34.2, 40.1, 44.5, 47.0, 48.5];
    else if (state.currentThreatLevel === 'waspada_karhutla') dataset = [26.5, 27.2, 29.5, 32.0, 35.4, 37.1, 38.5];
    else dataset = [26.5, 26.6, 26.5, 26.8, 26.4, 26.5, 26.5];
  } else if (metric === 'humidity') {
    label = 'Kelembapan Udara DHT22 (%)';
    color = '#14B8A6';
    if (state.currentThreatLevel === 'awas_karhutla') dataset = [72, 60, 48, 35, 25, 20, 18];
    else dataset = [72, 71, 73, 70, 72, 72, 72];
  }

  mainChartInstance.data.datasets[0].label = label;
  mainChartInstance.data.datasets[0].data = dataset;
  mainChartInstance.data.datasets[0].borderColor = color;
  mainChartInstance.data.datasets[0].backgroundColor = `${color}1A`;
  mainChartInstance.data.datasets[0].pointBackgroundColor = color;
  mainChartInstance.update();
}

function resizeCanvases() {
  resizeMapCanvas();
  resizeConsensusCanvas();
  if (mainChartInstance) mainChartInstance.resize();
}

// ==========================================================================
// 5. Threat Level Simulator Engine (Dual Hazard Logic)
// ==========================================================================
function triggerSimulation(level) {
  state.currentThreatLevel = level;

  // Update simulator pill active state
  document.querySelectorAll('.sim-pill').forEach(pill => {
    pill.classList.remove('active');
  });

  const activePill = document.querySelector(`.sim-pill.sim-${level.replace('_', '-')}`);
  if (activePill) activePill.classList.add('active');

  const card = document.getElementById('mainStatusCard');
  const iconBox = document.getElementById('statusIconBox');
  const badgeLabel = document.getElementById('statusBadgeLabel');
  const title = document.getElementById('statusTitle');
  const desc = document.getElementById('statusDesc');
  const consensusRatioText = document.getElementById('consensusRatioText');

  // Metrics DOM elements
  const valTilt = document.getElementById('valTilt');
  const subTilt = document.getElementById('subTilt');
  const valSoil = document.getElementById('valSoil');
  const subSoil = document.getElementById('subSoil');
  const valTemp = document.getElementById('valTemp');
  const subTemp = document.getElementById('subTemp');
  const valHumidity = document.getElementById('valHumidity');
  const subHumidity = document.getElementById('subHumidity');
  const valFDI = document.getElementById('valFDI');
  const subFDI = document.getElementById('subFDI');
  const valSVI = document.getElementById('valSVI');
  const subSVI = document.getElementById('subSVI');

  // Reset card styles
  card.className = 'hero-status-card';

  if (level === 'aman') {
    card.classList.add('status-aman-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">check_circle</span>';
    badgeLabel.innerText = 'SECTOR 3 — STABIL & AMAN';
    title.innerText = 'KONDISI LERENG & HUTAN STABIL';
    desc.innerText = 'Seluruh 3 node sensor beroperasi normal. Tidak ada pergeseran tanah maupun titik panas kebakaran terdeteksi.';
    consensusRatioText.innerText = '3/3 SEPAKAT (100%)';
    consensusRatioText.style.color = '#10B981';

    Object.keys(state.nodes).forEach(k => {
      state.nodes[k].status = 'aman';
      state.nodes[k].tilt = 1.2;
      state.nodes[k].soil = 65;
      state.nodes[k].temp = 26.5;
      state.nodes[k].humidity = 72;
    });

    valTilt.innerText = '1.2';
    subTilt.innerHTML = '<i class="fa-solid fa-check text-emerald"></i> Normal (< 2.0°)';

    valSoil.innerText = '65';
    subSoil.innerHTML = '<i class="fa-solid fa-check text-emerald"></i> Optimal (< 80%)';

    valTemp.innerText = '26.5';
    subTemp.innerHTML = '<i class="fa-solid fa-check text-emerald"></i> Sejuk (< 35°C)';

    valHumidity.innerText = '72';
    subHumidity.innerHTML = '<i class="fa-solid fa-check text-emerald"></i> Lembap Udara';

    valFDI.innerText = '0.12';
    subFDI.innerHTML = '<i class="fa-solid fa-shield text-emerald"></i> AMAN KARHUTLA';

    valSVI.innerText = '0.18';
    subSVI.innerHTML = '<i class="fa-solid fa-shield text-emerald"></i> AMAN LONGSOR';

    logEvent('info', 'Simulasi diubah: KONDISI SEKTOR STABIL & AMAN.');
  }

  else if (level === 'waspada_longsor') {
    card.classList.add('status-waspada-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">warning</span>';
    badgeLabel.innerText = 'WASPADA — ANOMALI PERGERAKAN TEBING';
    title.innerText = 'WASPADA: PERGERAKAN TEBING LOKAL';
    desc.innerText = 'Node 01 mendeteksi peningkatan kemiringan (3.8°), namun Node 02 & 03 masih stabil. Sistem memverifikasi anomali lokal.';
    consensusRatioText.innerText = '1/3 NODE AKTIF (UNVERIFIED)';
    consensusRatioText.style.color = '#F59E0B';

    state.nodes['Node 01'].status = 'waspada_longsor';
    state.nodes['Node 01'].tilt = 3.8;
    state.nodes['Node 01'].soil = 78;

    valTilt.innerText = '3.8';
    subTilt.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-amber"></i> Peningkatan (> 2.0°)';

    valSoil.innerText = '78';
    subSoil.innerHTML = '<i class="fa-solid fa-droplet text-amber"></i> Tinggi';

    valSVI.innerText = '0.52';
    subSVI.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-amber"></i> WASPADA';

    logEvent('warn', 'WASPADA LONGSOR: Node 01 memicu motion interrupt (3.8°). Consensus: Anomali Lokal.');
  }

  else if (level === 'waspada_karhutla') {
    card.classList.add('status-karhutla-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">local_fire_department</span>';
    badgeLabel.innerText = 'WASPADA — LONJAKAN PANAS UDARA';
    title.innerText = 'WASPADA: POTENSI KEBAKARAN HUTAN';
    desc.innerText = 'Sensor DHT22 pada Node 01 membaca lonjakan suhu udara (38.5°C) & penurunan kelembapan (32%). Indikasi awal Karhutla.';
    consensusRatioText.innerText = '1/3 NODE AKTIF (HEAT SPIKE)';
    consensusRatioText.style.color = '#EA580C';

    state.nodes['Node 01'].status = 'waspada_karhutla';
    state.nodes['Node 01'].temp = 38.5;
    state.nodes['Node 01'].humidity = 32;

    valTemp.innerText = '38.5';
    subTemp.innerHTML = '<i class="fa-solid fa-fire text-flame"></i> Panas Eksrem (> 35°C)';

    valHumidity.innerText = '32';
    subHumidity.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-flame"></i> Kering Udara';

    valFDI.innerText = '0.58';
    subFDI.innerHTML = '<i class="fa-solid fa-fire text-flame"></i> WASPADA KARHUTLA';

    logEvent('karhutla', 'WASPADA KARHUTLA: DHT22 Node 01 mendeteksi suhu 38.5°C & RH 32%. Peringatan awal titik panas.');
  }

  else if (level === 'siaga') {
    card.classList.add('status-siaga-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">notifications_active</span>';
    badgeLabel.innerText = 'SIAGA — KONSENSUS 2 NODE TERKONFIRMASI';
    title.innerText = 'SIAGA BENCANA: 2 NODE AKTIF!';
    desc.innerText = 'Node 01 & Node 02 terkonfirmasi mengalami anomali bersamaan. Sinyal peringatan awal terkirim via Push Notifikasi Aplikasi Mobile.';
    consensusRatioText.innerText = '2/3 NODE KONSENSUS (MATCHED)';
    consensusRatioText.style.color = '#F97316';

    state.nodes['Node 01'].status = 'siaga';
    state.nodes['Node 01'].tilt = 7.8;
    state.nodes['Node 02'].status = 'siaga';
    state.nodes['Node 02'].tilt = 7.1;

    valTilt.innerText = '7.5';
    subTilt.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-flame"></i> SIAGA (> 5.0°)';

    valSVI.innerText = '0.74';
    subSVI.innerHTML = '<i class="fa-solid fa-bell text-flame"></i> SIAGA BENCANA';

    logEvent('warn', 'SIAGA BENCANA! Multi-node verifikasi: 2 Node (01 & 02) terkonfirmasi mendeteksi pergerakan.');
  }

  else if (level === 'awas_longsor') {
    card.classList.add('status-awas-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">report_problem</span>';
    badgeLabel.innerText = 'AWAS — BAHAYA LONGSOR EKSTREM!';
    title.innerText = 'AWAS! BAHAYA LONGSOR - EVAKUASI!';
    desc.innerText = 'Seluruh 3 node sensor memvalidasi pergerakan tebing ekstrem (> 15.0°). SIRINE LOKAL 120dB BERBUNYI OTOMATIS & PUSH NOTIFIKASI MOBILE AKTIF!';
    consensusRatioText.innerText = '3/3 KONSENSUS BAHAYA (100%)';
    consensusRatioText.style.color = '#EF4444';

    Object.keys(state.nodes).forEach(k => {
      state.nodes[k].status = 'awas_longsor';
      state.nodes[k].tilt = 15.2;
      state.nodes[k].soil = 96;
    });

    valTilt.innerText = '15.2';
    subTilt.innerHTML = '<i class="fa-solid fa-circle-exclamation text-awas"></i> KEMIRINGAN EKSTREM';

    valSoil.innerText = '96';
    subSoil.innerHTML = '<i class="fa-solid fa-water text-awas"></i> Jenuh Total';

    valSVI.innerText = '0.94';
    subSVI.innerHTML = '<i class="fa-solid fa-circle-exclamation text-awas"></i> BAHAYA LONGSOR';

    playAlertTone();
    showSirenToast('EMERGENCY LONGSOR!', 'Sirine fisik 120dB aktif otomatis di lereng. Push notifikasi aplikasi mobile menyiarkan perintah evakuasi.');
    logEvent('longsor', 'AWAS LONGSOR! Deteksi pergeseran tebing tervalidasi 3-Node! Sirine 120dB aktif (<500ms). Push notifikasi aplikasi mobile terkirim.');
  }

  else if (level === 'awas_karhutla') {
    card.classList.add('status-awas-style');
    iconBox.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1;">local_fire_department</span>';
    badgeLabel.innerText = 'AWAS — BAHAYA KEBAKARAN HUTAN!';
    title.innerText = 'AWAS! KEBAKARAN HUTAN TERDETEKSI!';
    desc.innerText = 'Sensor DHT22 pada 3 Node memvalidasi suhu udara ekstrem (48.5°C) & kelembapan sangat kering (18%). SIRINE & PUSH NOTIFIKASI MOBILE AKTIF!';
    consensusRatioText.innerText = '3/3 KONSENSUS KARHUTLA (100%)';
    consensusRatioText.style.color = '#DC2626';

    Object.keys(state.nodes).forEach(k => {
      state.nodes[k].status = 'awas_karhutla';
      state.nodes[k].temp = 48.5;
      state.nodes[k].humidity = 18;
    });

    valTemp.innerText = '48.5';
    subTemp.innerHTML = '<i class="fa-solid fa-fire text-awas"></i> PANAS EKSTREM';

    valHumidity.innerText = '18';
    subHumidity.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-awas"></i> SANGAT KERING';

    valFDI.innerText = '0.96';
    subFDI.innerHTML = '<i class="fa-solid fa-circle-exclamation text-awas"></i> BAHAYA KARHUTLA';

    playAlertTone();
    showSirenToast('EMERGENCY KARHUTLA!', 'Suhu udara 48.5°C & RH 18% tervalidasi 3-Node! Sirine 120dB & Push Notifikasi Mobile terkirim.');
    logEvent('karhutla', 'AWAS KARHUTLA! Multi-node verifikasi titik panas hutan! Sirine 120dB aktif & Push Notifikasi Mobile terkirim.');
  }

  updateChartData();
  if (state.selectedNode) showNodePopup(state.selectedNode);
}

// ==========================================================================
// 6. Event Log Stream Controller
// ==========================================================================
function logEvent(type, message) {
  const container = document.getElementById('eventLogContainer');
  if (!container) return;

  const now = new Date();
  const timeStr = now.toLocaleTimeString('id-ID', { hour12: false });

  const row = document.createElement('div');
  row.className = `log-row log-${type}`;

  let tagText = 'INFO';
  let tagClass = 'tag-info';
  if (type === 'warn') { tagText = 'WASPADA'; tagClass = 'tag-warn'; }
  if (type === 'longsor') { tagText = 'LONGSOR'; tagClass = 'tag-longsor'; }
  if (type === 'karhutla') { tagText = 'KARHUTLA'; tagClass = 'tag-karhutla'; }

  row.innerHTML = `
    <span class="log-time">[${timeStr}]</span>
    <span class="log-tag ${tagClass}">${tagText}</span>
    <span class="log-message">${message}</span>
  `;

  container.insertBefore(row, container.firstChild);
}

function filterLogs(category) {
  document.querySelectorAll('.log-filter-btn').forEach(btn => btn.classList.remove('active'));
  event.target.classList.add('active');

  const rows = document.querySelectorAll('.log-row');
  rows.forEach(row => {
    if (category === 'all') {
      row.style.display = 'flex';
    } else {
      if (row.classList.contains(`log-${category}`)) row.style.display = 'flex';
      else row.style.display = 'none';
    }
  });
}

// ==========================================================================
// 7. Security PIN Confirmation Modal & Audio Alert
// ==========================================================================
function openPinModal(actionType) {
  state.pendingAction = actionType;
  const backdrop = document.getElementById('pinModalBackdrop');
  const title = document.getElementById('modalTitle');
  const desc = document.getElementById('modalDesc');

  clearPinInputs();

  if (actionType === 'siren') {
    title.innerText = 'Konfirmasi Uji Sirine Fisik';
    desc.innerText = 'Masukkan PIN keamanan 4-digit untuk membunyikan sirine 120dB & LED strobe di lokasi lereng selama 5 detik.';
  } else if (actionType === 'bpbd') {
    title.innerText = 'Konfirmasi Push Notifikasi Mobile';
    desc.innerText = 'Masukkan PIN keamanan 4-digit untuk menyiarkan push notifikasi darurat ke aplikasi mobile pengguna.';
  }

  if (backdrop) backdrop.classList.add('active');
  const p1 = document.getElementById('pin1');
  if (p1) p1.focus();
}

function closePinModal() {
  const backdrop = document.getElementById('pinModalBackdrop');
  if (backdrop) backdrop.classList.remove('active');
  state.pendingAction = null;
  clearPinInputs();
}

function movePinFocus(currentInput, nextInputId) {
  if (currentInput.value.length >= 1) {
    const nextInput = document.getElementById(nextInputId);
    if (nextInput) nextInput.focus();
  }
}

function clearPinInputs() {
  ['pin1', 'pin2', 'pin3', 'pin4'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
}

function verifyPinSubmit() {
  const pin = ['pin1', 'pin2', 'pin3', 'pin4'].map(id => document.getElementById(id).value).join('');

  if (pin === '1234') {
    closePinModal();
    if (state.pendingAction === 'siren') {
      showSirenToast('UJI SIRINE LOKAL BERHASIL!', 'Relay GPIO 26 aktif. Sirine 120dB & LED Strobe berbunyi selama 5 detik di lokasi.');
      logEvent('info', 'Uji Sirine Fisik 120dB dipicu manual oleh pengguna (PIN Verified). Relay aktif 5 detik.');
    } else if (state.pendingAction === 'bpbd') {
      showSirenToast('PUSH NOTIFIKASI TERKIRIM!', 'Notifikasi telemetri & koordinat berhasil dikirim ke aplikasi mobile.');
      logEvent('info', 'Push notifikasi darurat terkirim ke aplikasi mobile (PIN Verified).');
    }
  } else {
    alert('PIN Keamanan salah! Default demo PIN: 1234');
    clearPinInputs();
    document.getElementById('pin1').focus();
  }
}

function showSirenToast(titleText, descText) {
  const toast = document.getElementById('sirenToast');
  const title = document.getElementById('toastTitle');
  const desc = document.getElementById('toastDesc');

  if (title) title.innerText = titleText;
  if (desc) desc.innerText = descText;

  if (toast) {
    toast.classList.add('active');
    setTimeout(() => {
      toast.classList.remove('active');
    }, 4000);
  }
}

function playAlertTone() {
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(880, audioCtx.currentTime); // A5 tone
    gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.4);
  } catch (e) {
    console.log('Audio tone prevented by browser autoplay policy.');
  }
}

function downloadReport() {
  showSirenToast('MENGUNDUH LAPORAN PDF', 'Laporan telemetri sensor 24 jam TITEN EWS sedang diproses...');
  logEvent('info', 'Laporan PDF telemetri 24 jam diekspor oleh pengguna.');
}
