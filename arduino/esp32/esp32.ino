#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ══════════════════════════
// KONFIGURASI
// ══════════════════════════
const char* ssid     = "dishub";
const char* password = "12345678";
const char* BASE_URL = "http://10.92.132.166:5001";

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, 16, 17); // RX=16, TX=17

  Serial.print("Konek WiFi");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi OK! IP: " + WiFi.localIP().toString());
}

// ══════════════════════════
// KIRIM SENSOR KE BACKEND
// ══════════════════════════
void kirimSensor(String kotak, float ph, float tds, bool wl) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(String(BASE_URL) + "/api/sensor");
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<200> doc;
  doc["kotak"]       = kotak;
  doc["ph"]          = ph;
  doc["tds"]         = tds;
  doc["water_level"] = wl;

  String body;
  serializeJson(doc, body);

  int code = http.POST(body);
  Serial.println(code == 200 ? "✓ " + kotak : "✗ " + kotak + " gagal:" + String(code));
  http.end();
}

// ══════════════════════════
// CEK STATUS POMPA DARI BACKEND
// ══════════════════════════
void cekDanKirimPompa() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(String(BASE_URL) + "/api/pompa/status");
  int code = http.GET();

  if (code == 200) {
    String res = http.getString();

    StaticJsonDocument<1024> doc;
    deserializeJson(doc, res);

    // Buat perintah pompa untuk Mega
    String cmd = "POMPA:";
    cmd += doc["pompa_1"]["status"] == "on" ? "1" : "0";
    cmd += doc["pompa_2"]["status"] == "on" ? "1" : "0";
    cmd += doc["pompa_3"]["status"] == "on" ? "1" : "0";
    cmd += doc["pompa_4"]["status"] == "on" ? "1" : "0";
    cmd += doc["pompa_5"]["status"] == "on" ? "1" : "0";
    cmd += doc["pompa_6"]["status"] == "on" ? "1" : "0";

    Serial2.println(cmd);
    Serial.println("Kirim ke Mega: " + cmd);
  } else {
    Serial.println("Gagal cek pompa: " + String(code));
  }
  http.end();
}

// ══════════════════════════
// LOOP
// ══════════════════════════
void loop() {
  // Terima data dari Mega
  if (Serial2.available()) {
    String data = Serial2.readStringUntil('\n');
    data.trim();
    Serial.println("Dari Mega: " + data);

    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, data);

    if (!err) {
      kirimSensor("kotak_1", doc["k1"]["ph"], doc["k1"]["tds"], doc["k1"]["wl"]);
      kirimSensor("kotak_2", doc["k2"]["ph"], doc["k2"]["tds"], false);
      kirimSensor("kotak_3", doc["k3"]["ph"], doc["k3"]["tds"], false);
      kirimSensor("kotak_4", doc["k4"]["ph"], doc["k4"]["tds"], false);
    } else {
      Serial.println("Parse gagal: " + String(err.c_str()));
    }
  }

  // Cek pompa dari backend tiap 3 detik
  static unsigned long lastCek = 0;
  if (millis() - lastCek >= 3000) {
    lastCek = millis();
    cekDanKirimPompa();
  }
}