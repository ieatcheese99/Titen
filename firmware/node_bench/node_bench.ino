// TITEN: uji sensor lewat USB. Tidak ada deep sleep, LoRa, atau output alarm.
// Board ESP32-S3; library sama dengan node_sensor. Data gagal tetap null.
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <math.h>

constexpr uint8_t SDA_PIN = 8, SCL_PIN = 9, SOIL_PIN = 1;
constexpr uint8_t DHT_PIN = 2, FLAME_PIN = 3;
constexpr uint32_t SAMPLE_MS = 2500;
Adafruit_MPU6050 mpu;
DHT dht(DHT_PIN, DHT22);
bool mpuEnabled = true, dhtEnabled = true;
// Input analog/digital yang kosong tidak dapat dibedakan dari sensor terpasang.
// Aktifkan dari halaman uji hanya setelah wiring soil/flame dikonfirmasi.
bool soilEnabled = false, flameEnabled = false, mpuReady = false;
uint8_t mpuAddress = 0x68;
uint32_t sequence = 0, lastSample = 0;
String command;

void printNumber(float value, uint8_t decimals = 2) {
  if (isfinite(value)) Serial.print(value, decimals);
  else Serial.print("null");
}

void readCommands() {
  while (Serial.available()) {
    char ch = Serial.read();
    if (ch == '\r') continue;
    if (ch == '\n') {
      command.trim();
      if (command == "SOIL ON") soilEnabled = true;
      else if (command == "SOIL OFF") soilEnabled = false;
      else if (command == "FLAME ON") flameEnabled = true;
      else if (command == "FLAME OFF") flameEnabled = false;
      else if (command == "MPU ON") { mpuEnabled = true; mpuReady = false; }
      else if (command == "MPU OFF") { mpuEnabled = false; mpuReady = false; }
      else if (command == "DHT ON") dhtEnabled = true;
      else if (command == "DHT OFF") dhtEnabled = false;
      command = "";
    } else if (command.length() < 48) command += ch;
    else command = "";
  }
}

void sampleSensors() {
  float tilt = NAN, ax = NAN, ay = NAN, az = NAN;
  float airTemp = NAN, airHum = NAN;
  const char *mpuStatus = mpuEnabled ? "missing" : "disabled";
  if (mpuEnabled) {
    // Probe lagi tiap sampel jika sensor sebelumnya tidak terdeteksi.
    if (!mpuReady) {
      mpuAddress = 0x68;
      mpuReady = mpu.begin(mpuAddress, &Wire);
      if (!mpuReady) { mpuAddress = 0x69; mpuReady = mpu.begin(mpuAddress, &Wire); }
      if (mpuReady) {
        mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
        mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
      }
    }
    if (mpuReady) {
      Wire.beginTransmission(mpuAddress);
      if (Wire.endTransmission() != 0) mpuReady = false;
    }
    if (mpuReady) {
      sensors_event_t a{}, g{}, t{};
      if (mpu.getEvent(&a, &g, &t)) {
        ax = a.acceleration.x; ay = a.acceleration.y; az = a.acceleration.z;
        if (isfinite(ax) && isfinite(ay) && isfinite(az) &&
            (ax * ax + ay * ay + az * az) > 0.01f) {
          tilt = fabsf(atan2f(ay, sqrtf(ax * ax + az * az)) * 180.0f / PI);
          mpuStatus = "ok";
        } else mpuStatus = "read_error";
      } else { mpuStatus = "read_error"; mpuReady = false; }
    }
  }
  if (dhtEnabled) {
    airTemp = dht.readTemperature(); airHum = dht.readHumidity();
  }
  const char *dhtStatus = !dhtEnabled ? "disabled" :
    (isfinite(airTemp) && isfinite(airHum) ? "ok" : "read_error");

  Serial.printf("{\"type\":\"titen_bench\",\"node_id\":1,\"sequence\":%lu,\"uptime_ms\":%lu,",
                (unsigned long)++sequence, (unsigned long)millis());
  Serial.printf("\"mpu_status\":\"%s\",\"dht_status\":\"%s\",", mpuStatus, dhtStatus);
  Serial.printf("\"soil_enabled\":%s,\"flame_enabled\":%s,",
                soilEnabled ? "true" : "false", flameEnabled ? "true" : "false");
  Serial.print("\"tilt_deg\":"); printNumber(tilt);
  Serial.print(",\"accel_x\":"); printNumber(ax);
  Serial.print(",\"accel_y\":"); printNumber(ay);
  Serial.print(",\"accel_z\":"); printNumber(az);
  Serial.print(",\"air_temp_c\":"); printNumber(airTemp);
  Serial.print(",\"air_humidity_pct\":"); printNumber(airHum);
  Serial.print(",\"soil_raw\":");
  if (soilEnabled) Serial.print(analogRead(SOIL_PIN)); else Serial.print("null");
  Serial.print(",\"flame_detected\":");
  if (flameEnabled) Serial.print(digitalRead(FLAME_PIN) == LOW ? "true" : "false");
  else Serial.print("null");
  Serial.println(",\"battery_pct\":null,\"alarm_tested\":false,\"lora_tested\":false}");
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setTimeOut(100);
  dht.begin();
  pinMode(FLAME_PIN, INPUT_PULLUP);
  analogReadResolution(12);
  // Jangan menunggu Serial: sampel tetap berjalan saat browser belum terhubung.
  lastSample = millis();
}

void loop() {
  readCommands();
  if ((uint32_t)(millis() - lastSample) >= SAMPLE_MS) {
    lastSample = millis();
    sampleSensors();
  }
  delay(2);
}
