'use strict';
// Protokol khusus node_bench; bukan data simulasi atau gateway cloud.
function parseBenchLine(line) {
  let data;
  try { data = JSON.parse(line); } catch { return null; }
  if (!data || data.type !== 'titen_bench' || data.node_id !== 1 ||
      !Number.isInteger(data.sequence) || data.sequence < 1 ||
      !Number.isFinite(data.uptime_ms) || data.uptime_ms < 0) return null;
  for (const key of ['tilt_deg', 'accel_x', 'accel_y', 'accel_z', 'air_temp_c', 'air_humidity_pct', 'soil_raw']) {
    if (data[key] !== null && !Number.isFinite(data[key])) return null;
  }
  if (!['ok', 'missing', 'disabled', 'read_error'].includes(data.mpu_status) ||
      !['ok', 'disabled', 'read_error'].includes(data.dht_status) ||
      typeof data.soil_enabled !== 'boolean' || typeof data.flame_enabled !== 'boolean' ||
      !(data.flame_detected === null || typeof data.flame_detected === 'boolean')) return null;
  return data;
}

if (typeof module !== 'undefined') module.exports = { parseBenchLine };

if (typeof document !== 'undefined') {
  const el = (id) => document.getElementById(id);
  let port = null, reader = null, reading = null, closing = false, writeChain = Promise.resolve();
  let lastReceived = null, count = 0;
  const samples = [], logs = [];
  const controls = [['mpu-enabled', 'MPU'], ['dht-enabled', 'DHT'], ['soil-enabled', 'SOIL'], ['flame-enabled', 'FLAME']];
  const label = { ok: 'Pembacaan tersedia', missing: 'Tidak terdeteksi di I2C 0x68 / 0x69', disabled: 'Belum diuji', read_error: 'Tidak terbaca; periksa wiring' };
  const number = (v, unit, digits = 1) => v === null ? '—' : `${v.toFixed(digits)}${unit}`;
  function log(text) { logs.push(text); if (logs.length > 35) logs.shift(); el('log').textContent = logs.join('\n'); }
  function resetValues() {
    for (const id of ['tilt', 'temp', 'humidity', 'soil', 'flame']) el(id).textContent = '—';
    for (const id of ['mpu-state', 'dht-state', 'soil-state', 'flame-state']) el(id).textContent = 'Menunggu data';
    lastReceived = null;
  }
  function setConnected(value) {
    el('connect').disabled = value; el('disconnect').disabled = !value;
    controls.forEach(([id]) => { el(id).disabled = !value; });
    el('connection').textContent = value ? 'USB terhubung · menunggu sampel' : 'Belum terhubung';
  }
  function receive(data) {
    const receivedAt = new Date().toISOString();
    lastReceived = Date.now(); count += 1;
    samples.push({ ...data, received_at: receivedAt, source: 'usb_bench' });
    if (samples.length > 500) samples.shift();
    el('connection').textContent = 'Data node diterima lewat USB';
    el('tilt').textContent = number(data.tilt_deg, '°');
    el('temp').textContent = number(data.air_temp_c, ' °C');
    el('humidity').textContent = number(data.air_humidity_pct, ' %');
    el('soil').textContent = number(data.soil_raw, '', 0);
    el('flame').textContent = data.flame_detected === null ? '—' : data.flame_detected ? 'Terdeteksi' : 'Tidak';
    el('mpu-state').textContent = label[data.mpu_status]; el('dht-state').textContent = label[data.dht_status];
    el('soil-state').textContent = data.soil_enabled ? 'Input diaktifkan; angka ADC belum dikalibrasi' : 'Belum diuji';
    el('flame-state').textContent = data.flame_enabled ? 'Input diaktifkan; DO aktif LOW' : 'Belum diuji';
    const checked = [data.mpu_status !== 'disabled', data.dht_status !== 'disabled', data.soil_enabled, data.flame_enabled];
    controls.forEach(([id], i) => { el(id).checked = checked[i]; });
    el('count').textContent = String(count); el('sequence').textContent = `Urutan node: ${data.sequence}`;
    el('export').disabled = false;
    el('message').textContent = 'Ubah satu sensor pada satu waktu dan amati pembacaannya.';
  }
  async function readLoop() {
    const decoder = new TextDecoder(); let buffer = '';
    try {
      reader = port.readable.getReader();
      while (!closing) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        let newline;
        while ((newline = buffer.indexOf('\n')) !== -1) {
          const line = buffer.slice(0, newline).trim(); buffer = buffer.slice(newline + 1);
          if (!line) continue;
          log(line.slice(0, 2000)); const data = parseBenchLine(line);
          if (data) receive(data);
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
    try {
      await writeChain.catch(() => {});
      if (reader) await reader.cancel();
      if (reading) await reading;
      await port.close();
    } catch (error) { log(`Koneksi ditutup: ${error.message}`); }
    finally { port = null; reading = null; closing = false; setConnected(false); }
  }
  el('connect').addEventListener('click', async () => {
    el('connect').disabled = true;
    try {
      port = await navigator.serial.requestPort();
      await port.open({ baudRate: 115200, flowControl: 'none' });
      resetValues(); setConnected(true);
      el('message').textContent = 'Menunggu node_bench. Jika belum ada data, tekan RST sekali.';
      reading = readLoop();
      reading.then(() => { if (!closing) void closePort(); });
    } catch (error) {
      port = null; setConnected(false);
      el('message').textContent = error.name === 'NotFoundError' ? 'Pemilihan port dibatalkan.' : `Gagal membuka port: ${error.message}. Tutup Serial Monitor Arduino.`;
    }
  });
  el('disconnect').addEventListener('click', () => void closePort());
  controls.forEach(([id, command]) => el(id).addEventListener('change', () => {
    const checked = el(id).checked;
    writeChain = writeChain.then(async () => {
      if (!port || closing) return;
      const writer = port.writable.getWriter();
      try { await writer.write(new TextEncoder().encode(`${command} ${checked ? 'ON' : 'OFF'}\n`)); }
      finally { writer.releaseLock(); }
    }).catch((error) => { el('message').textContent = `Perubahan sensor gagal: ${error.message}`; });
  }));
  el('export').addEventListener('click', () => {
    const url = URL.createObjectURL(new Blob([JSON.stringify(samples, null, 2)], { type: 'application/json' }));
    const anchor = document.createElement('a'); anchor.href = url; anchor.download = 'titen-uji-usb.json'; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  setInterval(() => {
    if (lastReceived === null) { el('freshness').textContent = 'Belum ada sampel dari node.'; return; }
    const age = Math.floor((Date.now() - lastReceived) / 1000);
    el('freshness').textContent = `Sampel terakhir diterima ${age} detik lalu. ${age > 10 ? 'Data berhenti; periksa koneksi atau tekan RST.' : ''}`;
    if (port && age > 10) el('connection').textContent = 'Data terlambat · sampel terakhir tetap ditampilkan';
  }, 1000);
  if (!('serial' in navigator) || !window.isSecureContext) {
    el('connect').disabled = true;
    el('message').textContent = 'Web Serial belum tersedia. Buka halaman ini di Chrome/Edge desktop melalui http://localhost atau HTTPS.';
  }
}
