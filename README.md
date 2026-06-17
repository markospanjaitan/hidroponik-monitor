# 🌱 SISTEM MONITORING HIDROPONIK IoT

> Real-time Hydroponic Monitoring System menggunakan Flask API, PostgreSQL, Flutter, dan Tailscale VPN

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Flask](https://img.shields.io/badge/Flask-2.3+-000000?logo=flask)](https://flask.palletsprojects.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-316192?logo=postgresql)](https://www.postgresql.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-VPN-000000)](https://tailscale.com)

---

## 📋 Daftar Isi

- [Overview](#-overview)
- [Features](#-features)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Screenshots](#-screenshots)
- [Prerequisites](#-prerequisites)
- [Instalasi](#-instalasi)
  - [Server Setup](#1-server-setup-ubuntu-vmware)
  - [Database Setup](#2-database-setup-postgresql)
  - [Flask API Setup](#3-flask-api-setup)
  - [Tailscale Setup](#4-tailscale-setup)
  - [Mobile App Setup](#5-mobile-app-setup-flutter)
- [Konfigurasi](#-konfigurasi)
- [Penggunaan](#-penggunaan)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Testing](#-testing)
- [Troubleshooting](#-troubleshooting)
- [Future Development](#-future-development)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

## 🌟 Overview

Sistem monitoring hidroponik berbasis IoT yang memungkinkan monitoring real-time parameter penting seperti pH, TDS, suhu, kelembaban, level air, dan intensitas cahaya melalui aplikasi mobile atau web browser dari jarak jauh.

### Mengapa Sistem Ini?

- ✅ **Remote Monitoring** - Akses dari mana saja via Tailscale VPN
- ✅ **Real-time Data** - Update setiap 5 detik
- ✅ **Data Persistence** - Semua data tersimpan di PostgreSQL
- ✅ **User-Friendly** - UI mobile yang intuitif dengan Flutter
- ✅ **Secure** - Koneksi terenkripsi via Tailscale
- ✅ **Scalable** - Mudah ditambahkan sensor atau device baru

---

## 🚀 Features

### ✨ Current Features

- [x] Real-time monitoring 7 parameter sensor
- [x] Auto-refresh setiap 5 detik
- [x] Status indikator (OK/Warning) untuk setiap parameter
- [x] Remote access via Tailscale VPN
- [x] Data storage di PostgreSQL
- [x] RESTful API dengan Flask
- [x] Cross-platform mobile app (Flutter)
- [x] Connection status indicator

### 🔄 In Development

- [ ] Device control (pompa, lampu)
- [ ] Push notifications
- [ ] Data visualization (charts)
- [ ] Export data (CSV/Excel)
- [ ] Multi-user support

### 🎯 Future Plans

- [ ] Cloud deployment (24/7 uptime)
- [ ] Machine Learning untuk prediksi nutrisi
- [ ] WhatsApp Bot integration
- [ ] Web dashboard responsive
- [ ] Multi-device management

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────┐
│                  HARDWARE LAYER                         │
│  ESP32 + Sensors (pH, TDS, DHT22, DS18B20, etc)       │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTP POST
┌─────────────────────────────────────────────────────────┐
│                   SERVER LAYER                          │
│       VMware Ubuntu Server 24.04                        │
│  ┌──────────────────────────────────────────┐         │
│  │  Tailscale VPN (100.76.254.113)         │         │
│  └──────────────────────────────────────────┘         │
│  ┌──────────────────────────────────────────┐         │
│  │  Flask API (Port 5001)                   │         │
│  └──────────────────────────────────────────┘         │
│  ┌──────────────────────────────────────────┐         │
│  │  PostgreSQL Database                     │         │
│  └──────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────┘
                         ↓ Tailscale Network
┌─────────────────────────────────────────────────────────┐
│                   CLIENT LAYER                          │
│  Flutter Mobile App + Web Browser                      │
└─────────────────────────────────────────────────────────┘
```

**Tech Stack:**

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Hardware** | ESP32 | Microcontroller dengan WiFi |
| | pH Sensor | Mengukur pH larutan |
| | TDS Sensor | Mengukur konsentrasi nutrisi |
| | DHT22 | Suhu & kelembaban udara |
| | DS18B20 | Suhu air |
| | Ultrasonic | Level air |
| | LDR/BH1750 | Intensitas cahaya |
| **Server** | Ubuntu Server 24.04 | Operating system |
| | PostgreSQL 14 | Database |
| | Flask 2.3 | REST API framework |
| | Python 3.10+ | Programming language |
| | Tailscale | VPN untuk remote access |
| **Client** | Flutter 3.0+ | Cross-platform UI framework |
| | Dart | Programming language |
| | HTTP Package | API communication |

---

## 📱 Screenshots

### Mobile App

<table>
  <tr>
    <td><img src="screenshots/dashboard.jpg" width="250"/></td>
    <td><img src="screenshots/sensor-detail.jpg" width="250"/></td>
    <td><img src="screenshots/connection-status.jpg" width="250"/></td>
  </tr>
  <tr>
    <td align="center">Dashboard</td>
    <td align="center">Sensor Details</td>
    <td align="center">Connection Status</td>
  </tr>
</table>

### Web Browser

![API Response](screenshots/api-response.png)
*API Response JSON*

---

## 📦 Prerequisites

### Hardware Requirements

- **Laptop/PC untuk Server:**
  - Processor: Intel Core i5 atau setara
  - RAM: 8GB minimum (16GB recommended)
  - Storage: 50GB free space
  - OS: Windows 10/11 (untuk VMware)

- **Smartphone untuk Testing:**
  - Android 7.0 atau lebih tinggi
  - 2GB RAM minimum

- **Microcontroller & Sensors (Optional - untuk integrasi):**
  - ESP32 DevKit
  - pH Sensor Module
  - TDS/EC Sensor
  - DHT22
  - DS18B20
  - HC-SR04 Ultrasonic
  - LDR atau BH1750

### Software Requirements

**Server Side:**
- VMware Workstation 17 (atau VirtualBox)
- Ubuntu Server 24.04 ISO
- Tailscale Account (free tier)

**Development:**
- Git
- VS Code (atau text editor pilihan Anda)
- Postman (untuk API testing)
- pgAdmin (optional - untuk database management GUI)

**Mobile Development:**
- Flutter SDK 3.0+
- Android Studio atau VS Code dengan Flutter extension
- Android SDK

---

## 🔧 Instalasi

### 1. Server Setup (Ubuntu + VMware)

#### a. Install VMware & Create VM

```bash
# Download Ubuntu Server 24.04 ISO
# https://ubuntu.com/download/server

# Create VM di VMware:
# - Name: DWHS_PROJECT
# - Type: Linux
# - Version: Ubuntu 64-bit
# - RAM: 4GB
# - Disk: 50GB
# - Network: NAT atau Bridged
```

#### b. Install Ubuntu Server

```bash
# Boot dari ISO
# Follow installation wizard:
# - Hostname: serverkami
# - Username: dwhs
# - Password: [your-password]
# - Install OpenSSH Server: Yes

# Setelah install, login dan update:
sudo apt update && sudo apt upgrade -y
```

#### c. Install Dependencies

```bash
# Install Python & pip
sudo apt install python3 python3-pip python3-venv -y

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Install screen (untuk background process)
sudo apt install screen -y
```

---

### 2. Database Setup (PostgreSQL)

#### a. Configure PostgreSQL

```bash
# Login sebagai postgres user
sudo -u postgres psql

# Buat user database
CREATE USER dwhs WITH PASSWORD 'yourpassword';

# Buat database
CREATE DATABASE hydroponic_db OWNER dwhs;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE hydroponic_db TO dwhs;

# Exit
\q
```

#### b. Create Tables

```bash
# Login ke database
psql -U dwhs -d hydroponic_db

# Paste SQL script ini:
```

```sql
-- Tabel sensor_data
CREATE TABLE sensor_data (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    ph DECIMAL(4,2),
    tds DECIMAL(6,2),
    water_temp DECIMAL(4,2),
    air_temp DECIMAL(4,2),
    humidity DECIMAL(4,2),
    water_level DECIMAL(4,2),
    light_intensity INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO sensor_data (device_id, ph, tds, water_temp, air_temp, humidity, water_level, light_intensity) 
VALUES ('hydro_01', 6.5, 850.0, 24.5, 28.0, 65.0, 75.0, 800);

-- Verify
SELECT * FROM sensor_data;

-- Exit
\q
```

---

### 3. Flask API Setup

#### a. Create Project Directory

```bash
# Create directory
mkdir -p ~/hydroponic_api
cd ~/hydroponic_api

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate
```

#### b. Install Dependencies

```bash
# Install Flask & PostgreSQL adapter
pip install Flask Flask-CORS psycopg2-binary
```

#### c. Create Flask App

Create file `app.py`:

```python
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Database connection
def get_db_connection():
    conn = psycopg2.connect(
        host='localhost',
        database='hydroponic_db',
        user='dwhs',
        password='yourpassword'
    )
    return conn

# GET /api/sensor/latest - Get latest sensor data
@app.route('/api/sensor/latest', methods=['GET'])
def get_latest_sensor():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT 1')
    row = cur.fetchone()
    cur.close()
    conn.close()
    
    if row:
        data = {
            'id': row[0],
            'device_id': row[1],
            'ph': float(row[2]),
            'tds': float(row[3]),
            'water_temp': float(row[4]),
            'air_temp': float(row[5]),
            'humidity': float(row[6]),
            'water_level': float(row[7]),
            'light_intensity': row[8],
            'timestamp': row[9].isoformat()
        }
        return jsonify(data)
    return jsonify({'error': 'No data'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
```

#### d. Test Flask API

```bash
# Run Flask (test mode)
python app.py

# Di terminal lain, test API:
curl http://localhost:5001/api/sensor/latest

# Harusnya return JSON data ✅
```

#### e. Setup Auto-Start dengan Screen

```bash
# Stop Flask (Ctrl+C)

# Create screen session
screen -S flask

# Run Flask
cd ~/hydroponic_api
source venv/bin/activate
python app.py

# Detach dari screen: Ctrl+A lalu D
# Screen akan jalan di background ✅

# Untuk cek screen:
screen -ls

# Untuk attach kembali:
screen -r flask
```

---

### 4. Tailscale Setup

#### a. Install Tailscale di Ubuntu Server

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale & login
sudo tailscale up

# Ikuti link untuk login dengan akun Google/Microsoft/GitHub

# Setelah login, cek IP Tailscale:
tailscale ip -4

# Contoh output: 100.76.254.113 ✅
# Catat IP ini!
```

#### b. Install Tailscale di Laptop/HP

**Windows:**
```bash
# Download dari: https://tailscale.com/download/windows
# Install & login dengan akun yang sama
```

**Android:**
```bash
# Install dari Google Play Store
# Search: "Tailscale"
# Login dengan akun yang sama
```

#### c. Verify Connection

```bash
# Di Ubuntu Server, cek status:
tailscale status

# Harusnya muncul semua device yang terconnect:
# 100.76.254.113  serverkami      (you)
# 100.68.188.53   laptop-xxx      
# 100.79.163.67   phone-xxx       

# Test ping dari laptop ke server:
ping 100.76.254.113

# Test API dari laptop browser:
# http://100.76.254.113:5001/api/sensor/latest
```

---

### 5. Mobile App Setup (Flutter)

#### a. Install Flutter SDK

```bash
# Download Flutter: https://flutter.dev/docs/get-started/install

# Extract & add to PATH
# Windows: Edit Environment Variables
# Add: C:\flutter\bin

# Verify installation
flutter doctor

# Install dependencies yang kurang (Android SDK, dll)
```

#### b. Create Flutter Project

```bash
# Create project
flutter create hydroponic_monitor
cd hydroponic_monitor

# Open di VS Code
code .
```

#### c. Add Dependencies

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # Add this line
```

Lalu:
```bash
flutter pub get
```

#### d. Create Main App

Replace `lib/main.dart` dengan kode lengkap (lihat source code di repository).

Key sections:
```dart
// API URL - GANTI dengan IP Tailscale server Anda!
final String apiUrl = 'http://100.76.254.113:5001/api/sensor/latest';

// Fetch data function
Future<void> fetchSensorData() async {
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) {
    setState(() {
      sensorData = json.decode(response.body);
    });
  }
}

// Auto-refresh setiap 5 detik
_timer = Timer.periodic(const Duration(seconds: 5), (timer) {
  fetchSensorData();
});
```

#### e. Run di Device

**Via USB (Hot Reload):**
```bash
# Colok HP via USB
# Enable USB Debugging di HP

# Check device terdeteksi
flutter devices

# Run app
flutter run

# Edit kode → Save → Tekan 'r' untuk hot reload!
```

**Build APK:**
```bash
# Build release APK
flutter build apk --release

# File ada di: build/app/outputs/flutter-apk/app-release.apk

# Transfer ke HP via USB/WhatsApp
# Install APK di HP
```

---

## ⚙️ Konfigurasi

### Server Configuration

**File:** `~/hydroponic_api/app.py`

```python
# Database credentials
DB_CONFIG = {
    'host': 'localhost',
    'database': 'hydroponic_db',
    'user': 'dwhs',
    'password': 'yourpassword'  # ← GANTI!
}

# Server config
HOST = '0.0.0.0'  # Allow dari semua IP
PORT = 5001       # Port API
DEBUG = True      # Ganti False untuk production
```

### Flutter App Configuration

**File:** `lib/main.dart`

```dart
// API URL - GANTI dengan IP Tailscale server Anda!
final String apiUrl = 'http://100.76.254.113:5001/api/sensor/latest';

// Auto-refresh interval
final Duration refreshInterval = Duration(seconds: 5);

// Sensor thresholds (untuk indikator OK/Warning)
final Map<String, Map<String, double>> thresholds = {
  'ph': {'min': 5.5, 'max': 7.0},
  'tds': {'min': 800, 'max': 1000},
  'water_temp': {'min': 20, 'max': 28},
  'air_temp': {'min': 25, 'max': 30},
  'humidity': {'min': 60, 'max': 80},
  'water_level': {'min': 50, 'max': 100},
  'light_intensity': {'min': 500, 'max': 1000},
};
```

---

## 🎮 Penggunaan

### Daily Workflow

**1. Start Server (di laptop/PC):**
```bash
# Nyalakan VMware Ubuntu Server
# Tunggu 1-2 menit (Flask auto-start via screen)

# Optional: Cek Flask jalan
ssh dwhs@100.76.254.113
screen -ls  # Harusnya ada "flask (Detached)"
```

**2. Connect Tailscale (di HP):**
```bash
# Buka aplikasi Tailscale
# Tap "Connect"
# Tunggu sampai status "Connected" ✅
```

**3. Buka Aplikasi (di HP):**
```bash
# Tap icon "Hydroponic Monitor"
# Dashboard langsung muncul dengan data real-time ✅
# Data auto-refresh setiap 5 detik
```

### Monitoring via Web Browser

```bash
# Di laptop/HP, buka browser
# Pastikan Tailscale Connected

# Akses API:
http://100.76.254.113:5001/api/sensor/latest

# Harusnya muncul JSON data ✅
```

### Update Data (Manual - untuk testing)

```bash
# SSH ke server
ssh dwhs@100.76.254.113

# Login ke PostgreSQL
psql -U dwhs -d hydroponic_db

# Insert data baru
INSERT INTO sensor_data (device_id, ph, tds, water_temp, air_temp, humidity, water_level, light_intensity) 
VALUES ('hydro_01', 6.8, 920.0, 25.0, 29.5, 68.0, 80.0, 750);

# Exit
\q

# Data baru langsung muncul di app! ✅
```

---

## 📚 API Documentation

### Base URL
```
http://100.76.254.113:5001/api
```

### Endpoints

#### 1. Get Latest Sensor Data

**Endpoint:** `GET /sensor/latest`

**Description:** Mengambil data sensor terbaru dari database

**Request:**
```bash
curl -X GET http://100.76.254.113:5001/api/sensor/latest
```

**Response (200 OK):**
```json
{
  "id": 1,
  "device_id": "hydro_01",
  "ph": 6.5,
  "tds": 850.0,
  "water_temp": 24.5,
  "air_temp": 28.0,
  "humidity": 65.0,
  "water_level": 75.0,
  "light_intensity": 800,
  "timestamp": "2026-02-10T02:38:36.102130"
}
```

**Response (404 Not Found):**
```json
{
  "error": "No data"
}
```

---

## 🗄️ Database Schema

### Table: `sensor_data`

```sql
CREATE TABLE sensor_data (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    ph DECIMAL(4,2),
    tds DECIMAL(6,2),
    water_temp DECIMAL(4,2),
    air_temp DECIMAL(4,2),
    humidity DECIMAL(4,2),
    water_level DECIMAL(4,2),
    light_intensity INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Columns

| Column | Type | Constraint | Description |
|--------|------|------------|-------------|
| id | SERIAL | PRIMARY KEY | Auto-increment ID |
| device_id | VARCHAR(50) | NOT NULL | Device identifier |
| ph | DECIMAL(4,2) | | pH level (0.00-14.00) |
| tds | DECIMAL(6,2) | | TDS in ppm |
| water_temp | DECIMAL(4,2) | | Water temperature (°C) |
| air_temp | DECIMAL(4,2) | | Air temperature (°C) |
| humidity | DECIMAL(4,2) | | Air humidity (%) |
| water_level | DECIMAL(4,2) | | Water level (%) |
| light_intensity | INTEGER | | Light in lux |
| timestamp | TIMESTAMP | DEFAULT NOW() | Record timestamp |

---

## 🧪 Testing

### Test Server Connectivity

```bash
# SSH test
ssh dwhs@100.76.254.113

# Harusnya bisa login ✅
```

### Test Database

```bash
# Login ke PostgreSQL
psql -U dwhs -d hydroponic_db

# Query data
SELECT * FROM sensor_data;

# Harusnya ada data ✅

# Exit
\q
```

### Test Flask API

```bash
# Test dari server lokal
curl http://localhost:5001/api/sensor/latest

# Test dari Tailscale IP
curl http://100.76.254.113:5001/api/sensor/latest

# Harusnya return JSON ✅
```

### Test Mobile App

```bash
# Pastikan:
# 1. VMware Ubuntu running ✅
# 2. Flask API running ✅
# 3. Tailscale connected ✅

# Buka app → Dashboard harusnya muncul data ✅
```

### Test Cases

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Server SSH via Tailscale | Login success | ✅ PASS |
| Database query | Data returned | ✅ PASS |
| API GET /sensor/latest | JSON response | ✅ PASS |
| Mobile app dashboard | Data displayed | ✅ PASS |
| Auto-refresh (5s) | Data updates | ✅ PASS |
| Connection lost | "Disconnected" status | ✅ PASS |

---

## 🔍 Troubleshooting

### Mobile App Blank Putih / Error

**Problem:** Aplikasi terbuka tapi blank putih atau error koneksi

**Solution:**

1. **Cek Tailscale di HP:**
```bash
# Buka app Tailscale
# Pastikan status "Connected" (hijau)
# Kalau "Disconnected" → Tap "Connect"
```

2. **Cek Flask API:**
```bash
ssh dwhs@100.76.254.113
screen -ls

# Harusnya ada: "flask (Detached)"
# Kalau tidak ada:
cd ~/hydroponic_api
source venv/bin/activate
screen -S flask
python app.py
# Ctrl+A lalu D (detach)
```

3. **Test Koneksi di Browser HP:**
```bash
# Buka browser HP
# Ketik: http://100.76.254.113:5001/api/sensor/latest
# Harusnya muncul JSON

# Kalau error → Masalah di Tailscale/Flask
# Kalau JSON muncul → Masalah di kode Flutter
```

### Database Connection Error

**Problem:** Flask API error "could not connect to server"

**Solution:**

```bash
# Cek PostgreSQL running
sudo systemctl status postgresql

# Kalau tidak running:
sudo systemctl start postgresql

# Cek credentials di app.py
# Password harus sama dengan saat CREATE USER
```

### Tailscale Not Connected

**Problem:** Device tidak terlihat di `tailscale status`

**Solution:**

```bash
# Restart Tailscale
sudo tailscale down
sudo tailscale up

# Re-login
tailscale status
```

---

## 🚀 Future Development

### Short Term (1-2 bulan)

- [ ] **Device Control**
  - ON/OFF pompa nutrisi
  - ON/OFF lampu grow light
  - Tabel `device_control` di database
  - API endpoint `/api/device/control`

- [ ] **Notifications**
  - Push notification ke HP
  - Alert jika parameter di luar range
  - Firebase Cloud Messaging (FCM)

- [ ] **Data Visualization**
  - Grafik riwayat data (chart)
  - Trend analysis
  - Chart.js atau Flutter Charts package

- [ ] **Export Data**
  - Export ke CSV
  - Export ke Excel
  - Email report otomatis

### Long Term (3-6 bulan)

- [ ] **Cloud Deployment**
  - Deploy Flask API ke VPS (DigitalOcean/AWS)
  - 24/7 uptime
  - PostgreSQL di cloud

- [ ] **Machine Learning**
  - Prediksi kebutuhan nutrisi
  - Anomaly detection
  - TensorFlow Lite

- [ ] **Multi-User**
  - Sistem login/authentication
  - Role-based access (admin, user, viewer)
  - JWT token

- [ ] **Web Dashboard**
  - Responsive web dashboard
  - React.js atau Vue.js
  - Real-time dengan WebSocket

- [ ] **WhatsApp Bot**
  - Notifikasi via WhatsApp
  - Query data via chat
  - Twilio API

---

## 🤝 Contributing

Contributions are welcome! Silakan fork repository ini dan submit pull request.

### Development Workflow

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Coding Standards

- Python: Follow PEP 8
- Dart/Flutter: Follow Effective Dart guidelines
- SQL: Use lowercase with underscores
- Commit messages: Use conventional commits format

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

**Author:** [Nama Anda]

- Email: [email@example.com]
- GitHub: [@username](https://github.com/username)
- LinkedIn: [Profile](https://linkedin.com/in/username)

**Project Link:** [https://github.com/username/hydroponic-iot](https://github.com/username/hydroponic-iot)

---

## 🙏 Acknowledgments

- [Flask Documentation](https://flask.palletsprojects.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Tailscale Documentation](https://tailscale.com/kb/)
- Stack Overflow Community
- GitHub Open Source Community

---

## 📊 Project Stats

![GitHub stars](https://img.shields.io/github/stars/username/hydroponic-iot?style=social)
![GitHub forks](https://img.shields.io/github/forks/username/hydroponic-iot?style=social)
![GitHub issues](https://img.shields.io/github/issues/username/hydroponic-iot)
![GitHub license](https://img.shields.io/github/license/username/hydroponic-iot)

---

**Made with ❤️ for sustainable agriculture** 🌱
