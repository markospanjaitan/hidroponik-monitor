// ══════════════════════════════════════
// ARDUINO MEGA — HIDROPONIK
// Baca sensor → kirim ke ESP32
// Terima perintah pompa → kontrol relay
// ══════════════════════════════════════

#define PIN_PH_1   A0
#define PIN_PH_2   A1
#define PIN_PH_3   A2
#define PIN_PH_4   A3
#define PIN_TDS_1  A4
#define PIN_TDS_2  A5
#define PIN_TDS_3  A6
#define PIN_TDS_4  A7
#define PIN_WL     A8

#define RELAY_P1   2
#define RELAY_P2   3
#define RELAY_P3   4
#define RELAY_P4   5
#define RELAY_P5   6
#define RELAY_P6   7

#define WL_THRESHOLD 500

unsigned long lastKirim = 0;
const unsigned long INTERVAL_KIRIM = 5000;

// ══════════════════════════════════════
// BACA SENSOR pH
// ══════════════════════════════════════
float bacaPH(int pin) {
  long total = 0;
  for (int i = 0; i < 10; i++) {
    total += analogRead(pin);
    delay(5);
  }
  int raw    = total / 10;
  float volt = raw * (5.0 / 1023.0);
  float ph   = 7.0 + ((2.781 - volt) / 0.18); // kalibrasi
  return ph;
}

// ══════════════════════════════════════
// BACA SENSOR TDS
// ══════════════════════════════════════
float bacaTDS(int pin) {
  long total = 0;
  for (int i = 0; i < 10; i++) {
    total += analogRead(pin);
    delay(5);
  }
  int raw    = total / 10;
  float volt = raw * (5.0 / 1023.0);
  float tds  = (133.42 * volt * volt * volt
              - 255.86 * volt * volt
              + 857.39 * volt) * 0.5;
  tds = tds * 0.46; // faktor koreksi kalibrasi
  if (tds < 0) tds = 0;
  return tds;
}

// ══════════════════════════════════════
// BACA WATER LEVEL
// ══════════════════════════════════════
bool bacaWaterLevel() {
  return analogRead(PIN_WL) > WL_THRESHOLD;
}

// ══════════════════════════════════════
// PROSES PERINTAH POMPA DARI ESP32
// Format: POMPA:P1:on,P2:off,P3:off,...
// ══════════════════════════════════════
void prosesPerintahPompa(String cmd) {
  cmd.remove(0, 6); // hapus "POMPA:"

  int start = 0;
  while (start < (int)cmd.length()) {
    int comma = cmd.indexOf(',', start);
    if (comma == -1) comma = cmd.length();

    String item   = cmd.substring(start, comma);
    String kode   = item.substring(0, 2);
    String status = item.substring(3);
    status.trim();

    int pin = -1;
    if      (kode == "P1") pin = RELAY_P1;
    else if (kode == "P2") pin = RELAY_P2;
    else if (kode == "P3") pin = RELAY_P3;
    else if (kode == "P4") pin = RELAY_P4;
    else if (kode == "P5") pin = RELAY_P5;
    else if (kode == "P6") pin = RELAY_P6;

    if (pin != -1) {
      bool nyala = (status == "on");
      digitalWrite(pin, nyala ? LOW : HIGH);
      Serial.println("[RELAY] " + kode + " → " + status);
    }

    start = comma + 1;
  }
}

// ══════════════════════════════════════
// SETUP
// ══════════════════════════════════════
void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);

  int relayPins[] = {RELAY_P1, RELAY_P2, RELAY_P3,
                     RELAY_P4, RELAY_P5, RELAY_P6};
  for (int i = 0; i < 6; i++) {
    pinMode(relayPins[i], OUTPUT);
    digitalWrite(relayPins[i], HIGH);
  }

  Serial.println("=== MEGA HIDROPONIK READY ===");
  delay(1000);
}

// ══════════════════════════════════════
// LOOP
// ══════════════════════════════════════
void loop() {
  unsigned long now = millis();

  // Terima perintah pompa dari ESP32
  if (Serial1.available()) {
    String data = Serial1.readStringUntil('\n');
    data.trim();

    if (data.startsWith("POMPA:")) {
      Serial.println("[ESP32] " + data);
      prosesPerintahPompa(data);
    } else {
      int pompaIdx = data.indexOf("POMPA:");
      if (pompaIdx >= 0) {
        String bersih = data.substring(pompaIdx);
        Serial.println("[ESP32] " + bersih);
        prosesPerintahPompa(bersih);
      }
    }
  }

  // Kirim data sensor tiap 5 detik
  if (now - lastKirim >= INTERVAL_KIRIM) {
    lastKirim = now;

    float ph1  = bacaPH(PIN_PH_1);
    float ph2  = bacaPH(PIN_PH_2);
    float ph3  = bacaPH(PIN_PH_3);
    float ph4  = bacaPH(PIN_PH_4);
    float tds1 = bacaTDS(PIN_TDS_1);
    float tds2 = bacaTDS(PIN_TDS_2);
    float tds3 = bacaTDS(PIN_TDS_3);
    float tds4 = bacaTDS(PIN_TDS_4);
    bool  wl   = bacaWaterLevel();

    Serial.println("──────────────────────────────");
    Serial.print("pH  K1="); Serial.print(ph1, 2);
    Serial.print(" K2=");    Serial.print(ph2, 2);
    Serial.print(" K3=");    Serial.print(ph3, 2);
    Serial.print(" K4=");    Serial.println(ph4, 2);
    Serial.print("TDS K1="); Serial.print(tds1, 0);
    Serial.print(" K2=");    Serial.print(tds2, 0);
    Serial.print(" K3=");    Serial.print(tds3, 0);
    Serial.print(" K4=");    Serial.println(tds4, 0);
    Serial.print("WL     = ");
    Serial.println(wl ? "ADA AIR" : "KOSONG");
    Serial.println("──────────────────────────────");

    String json = "{";
    json += "\"k1\":{\"ph\":"  + String(ph1, 2) +
            ",\"tds\":"        + String(tds1, 0) +
            ",\"wl\":"         + String(wl ? "true" : "false") + "},";
    json += "\"k2\":{\"ph\":"  + String(ph2, 2) +
            ",\"tds\":"        + String(tds2, 0) + "},";
    json += "\"k3\":{\"ph\":"  + String(ph3, 2) +
            ",\"tds\":"        + String(tds3, 0) + "},";
    json += "\"k4\":{\"ph\":"  + String(ph4, 2) +
            ",\"tds\":"        + String(tds4, 0) + "}";
    json += "}";

    Serial1.println(json);
    Serial.println("[ESP32] Kirim: " + json);
  }
}