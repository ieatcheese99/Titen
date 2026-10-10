'use strict';

function parseGatewayLine(line) {
  let data;
  try { data = JSON.parse(line); } catch { return null; }
  if (!data || typeof data !== 'object' || Array.isArray(data) ||
      data.type === 'titen_bench' || !Number.isInteger(data.node_id) ||
      data.node_id < 1 || data.node_id > 255) return null;
  for (const key of ['battery_pct', 'tilt_deg', 'soil_moisture', 'air_temp', 'air_humidity', 'rssi', 'snr']) {
    if (!Number.isFinite(data[key])) return null;
  }
  if (!Number.isInteger(data.status_level) || data.status_level < 0 || data.status_level > 3 ||
      !Number.isInteger(data.hazard_type) || data.hazard_type < 0 || data.hazard_type > 2 ||
      data.battery_pct < 0 || data.battery_pct > 100 || data.soil_moisture < 0 ||
      data.soil_moisture > 100 || data.air_humidity < 0 || data.air_humidity > 100) return null;
  return data;
}
if (typeof module !== 'undefined') module.exports = { parseGatewayLine };

if (typeof document !== 'undefined') {
  const el = (id) => document.getElementById(id);
  let port = null, reader = null, reading = null, closing = false, lastReceived = null, count = 0;
  const samples = [], logs = [];
  const number = (value, unit, digits = 1) => `${value.toFixed(digits)}${unit}`;
  function log(line) {
    logs.push(line.slice(0, 2000)); if (logs.length > 40) logs.shift();
    el('log').textContent = logs.join('\n');
    if (line.includes('[OK] Gateway siap mendengarkan')) el('radio').textContent = 'Gateway melaporkan LoRa siap menerima.';
    if (line.includes('[ERR] LoRa Gateway')) el('radio').textContent = 'LoRa gagal dimulai; periksa kabel dan suplai modul.';
    if (line.includes('[WARN]') && line.includes('CRC16')) el('radio').textContent = 'Gateway menolak paket dengan CRC rusak.';
  }
  function connection(connected) {
    el('connect').disabled = connected; el('disconnect').disabled = !connected;
    el('connection').textContent = connected ? 'USB terhubung · menunggu LoRa' : 'USB belum terhubung';
  }
  function receive(data) {
    lastReceived = Date.now(); count += 1;
    samples.push({ ...data, source: 'gateway_serial', received_at: new Date().toISOString(), sensor_validity: 'unknown' });
    if (samples.length > 500) samples.shift();
    el('connection').textContent = 'Paket node diterima melalui gateway';
    el('radio').textContent = 'Gateway mengeluarkan telemetri LoRa.';
    el('node-id').textContent = `Node ${String(data.node_id).padStart(2, '0')}`;
    el('count').textContent = `${count} paket diterima browser`;
    el('tilt').textContent = number(data.tilt_deg, '°'); el('soil').textContent = number(data.soil_moisture, ' %', 0);
    el('temp').textContent = number(data.air_temp, ' °C'); el('humidity').textContent = number(data.air_humidity, ' %', 0);
    el('rssi').textContent = number(data.rssi, ' dBm', 0); el('snr').textContent = number(data.snr, ' dB');
    el('status').textContent = ['AMAN', 'WASPADA', 'SIAGA', 'AWAS'][data.status_level];
    el('hazard').textContent = `${['Jenis bahaya: tidak dilaporkan', 'Jenis: longsor', 'Jenis: karhutla'][data.hazard_type]} · validitas sensor belum terkonfirmasi`;
    el('message').textContent = 'Paket diterima. Tekan RST node untuk mengirim pembacaan berikutnya.';
    el('export').disabled = false;
  }
  function resetSession() {
    lastReceived = null; count = 0; samples.length = 0; logs.length = 0;
    for (const id of ['node-id', 'tilt', 'soil', 'temp', 'humidity', 'rssi', 'snr', 'status']) el(id).textContent = '—';
    el('count').textContent = '0 paket diterima browser'; el('hazard').textContent = 'Belum dinilai';
    el('radio').textContent = 'Kesiapan LoRa belum terkonfirmasi.'; el('log').textContent = 'Menunggu keluaran gateway…';
    el('freshness').textContent = 'Belum ada paket dari node.'; el('export').disabled = true;
  }
  async function readLoop() {
    const decoder = new TextDecoder(); let buffer = '';
    try {
      reader = port.readable.getReader();
      while (!closing) {
        const { value, done } = await reader.read(); if (done) break;
        buffer += decoder.decode(value, { stream: true });
        let newline;
        while ((newline = buffer.indexOf('\n')) !== -1) {
          const line = buffer.slice(0, newline).trim(); buffer = buffer.slice(newline + 1);
          if (!line) continue;
          log(line); const data = parseGatewayLine(line); if (data) receive(data);
        }
        if (buffer.length > 8192) { buffer = ''; log('Baris terlalu panjang diabaikan.'); }
      }
    } catch (error) {
      if (!closing) el('message').textContent = `Pembacaan berhenti: ${error.message}`;
    } finally { if (reader) { reader.releaseLock(); reader = null; } }
  }
  async function closePort() {
    if (!port || closing) return;
    closing = true; el('disconnect').disabled = true;
    try { if (reader) await reader.cancel(); if (reading) await reading; await port.close(); }
    catch (error) { log(`Koneksi ditutup: ${error.message}`); }
    finally { port = null; reading = null; closing = false; connection(false); }
  }
  el('connect').addEventListener('click', async () => {
    el('connect').disabled = true;
    try {
      port = await navigator.serial.requestPort(); await port.open({ baudRate: 115200, flowControl: 'none' });
      resetSession(); connection(true);
      el('message').textContent = 'Tekan RST gateway sekali, tunggu LoRa siap, lalu tekan RST node.';
      reading = readLoop(); reading.then(() => { if (!closing) void closePort(); });
    } catch (error) {
      port = null; connection(false);
      el('message').textContent = error.name === 'NotFoundError' ? 'Pemilihan port dibatalkan.' : `Gagal membuka port: ${error.message}. Tutup Serial Monitor/Plotter Arduino.`;
    }
  });
  el('disconnect').addEventListener('click', () => void closePort());
  el('export').addEventListener('click', () => {
    const url = URL.createObjectURL(new Blob([JSON.stringify(samples, null, 2)], { type: 'application/json' }));
    const anchor = document.createElement('a'); anchor.href = url; anchor.download = 'titen-uji-lora-gateway.json'; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  setInterval(() => {
    if (lastReceived === null) return;
    const age = Math.floor((Date.now() - lastReceived) / 1000);
    el('freshness').textContent = `Paket terakhir diterima ${age} detik lalu. ${age > 15 ? 'Data terakhir; belum ada paket berikutnya. Node biasa tidur 6 jam.' : ''}`;
    if (port && age > 15) el('connection').textContent = 'USB terhubung · menunggu paket berikutnya';
  }, 1000);
  if (!('serial' in navigator) || !window.isSecureContext) {
    el('connect').disabled = true;
    el('message').textContent = 'Buka halaman ini di Chrome/Edge desktop melalui http://localhost atau HTTPS untuk memakai Web Serial.';
  }
}
