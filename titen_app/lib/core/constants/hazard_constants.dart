/// Disaster Thresholds according to FR-1.4 and PRD specs
class HazardConstants {
  // Landslide thresholds (Longsor)
  static const double landslideTiltThresholdDeg = 5.0;      // Δθ > 5.0°
  static const double landslideSoilMoistureThreshold = 80.0; // Soil Moisture > 80%

  // Forest Fire thresholds (Karhutla)
  static const double karhutlaTempThresholdC = 45.0;        // Temp > 45.0°C
  static const double karhutlaHumidityThreshold = 25.0;     // Air Humidity < 25%

  // Default Siren Test PIN (US-05)
  static const String defaultSirenPin = "1234";

  // LoRa Frequency
  static const String loraFrequency = "915 MHz";

  // Deep sleep heartbeat interval
  static const Duration heartbeatInterval = Duration(hours: 6);
}
