import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

// ══════════════════════════════════════
// KONFIGURASI API
// ══════════════════════════════════════
const String tailscaleUrl = 'http://100.76.254.113:5001';
const String dhcpUrl      = 'http://10.92.132.166:5001';

class ApiService {
  static String baseUrl = tailscaleUrl;
  static bool   isConnected    = false;
  static String connectionType = '';

  static Future<void> detectConnection() async {
    try {
      final r = await http
          .get(Uri.parse('$tailscaleUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        baseUrl = tailscaleUrl; connectionType = 'Tailscale'; isConnected = true; return;
      }
    } catch (_) {}
    try {
      final r = await http
          .get(Uri.parse('$dhcpUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        baseUrl = dhcpUrl; connectionType = 'DHCP Lokal'; isConnected = true; return;
      }
    } catch (_) {}
    isConnected = false; connectionType = 'Offline';
  }

  static Future<Map<String, dynamic>> getSensorLatest() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/sensor/latest')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {}; }
  }

  static Future<List<dynamic>> getSensorHistory(String kotak, {int days = 7}) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/sensor/history?kotak=$kotak&days=$days')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> getSensorWeekly(String kotak) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/sensor/weekly?kotak=$kotak')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {}; }
  }

  static Future<Map<String, dynamic>> getPompaStatus() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/pompa/status')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {}; }
  }

  static Future<Map<String, dynamic>> getMode() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/mode')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {'mode': 'semi'}; }
  }

  static Future<bool> setMode(String mode) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/api/mode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': mode}),
      ).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> kontrolPompa(String pompa, String status, {String trigger = 'manual'}) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/api/pompa/control'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pompa': pompa, 'status': status, 'trigger': trigger}),
      ).timeout(const Duration(seconds: 5));
      final body = jsonDecode(r.body);
      return {'success': r.statusCode == 200, 'message': body['error'] ?? body['status'] ?? ''};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> getPengaturan() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/pengaturan')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {}; }
  }

  static Future<bool> simpanPengaturan(Map<String, dynamic> data) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/api/pengaturan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getLog({int limit = 20, String? trigger, String? kotak}) async {
    try {
      String url = '$baseUrl/api/log?limit=$limit';
      if (trigger != null) url += '&trigger=$trigger';
      if (kotak != null) url += '&kotak=$kotak';
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> getJadwal() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/jadwal')).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) { return {}; }
  }
}

// ══════════════════════════════════════
// COLORS
// ══════════════════════════════════════
class AppColors {
  static const Color bg      = Color(0xFF0A0A1A);
  static const Color card    = Color(0xFF12121F);
  static const Color border  = Color(0xFF2A1F4A);
  static const Color primary = Color(0xFFFF3B5C);
  static const Color blue    = Color(0xFF4D8AFF);
  static const Color grey    = Color(0xFF6A5A80);
  static const Color text    = Color(0xFFFFE0E8);
}

// ══════════════════════════════════════
// MODEL
// ══════════════════════════════════════
class SensorData {
  final String kotak;
  final double ph;
  final double tds;
  final bool   waterLevel;
  final String timestamp;
  final double phMin;
  final double phMax;
  final double tdsMin;
  final double tdsMax;

  SensorData({
    required this.kotak,
    required this.ph,
    required this.tds,
    required this.waterLevel,
    required this.timestamp,
    this.phMin  = 1.0,
    this.phMax  = 10.0,
    this.tdsMin = 700.0,
    this.tdsMax = 1000.0,
  });

  factory SensorData.fromJson(Map<String, dynamic> j) => SensorData(
    kotak:      j['kotak']       ?? '',
    ph:         (j['ph']         ?? 0.0).toDouble(),
    tds:        (j['tds']        ?? 0.0).toDouble(),
    waterLevel: j['water_level'] ?? false,
    timestamp:  j['timestamp']   ?? '',
  );

  factory SensorData.fromJsonWithBatas(
    Map<String, dynamic> j,
    Map<String, dynamic> setting,
  ) => SensorData(
    kotak:      j['kotak']       ?? '',
    ph:         (j['ph']         ?? 0.0).toDouble(),
    tds:        (j['tds']        ?? 0.0).toDouble(),
    waterLevel: j['water_level'] ?? false,
    timestamp:  j['timestamp']   ?? '',
    phMin:  (setting['ph_min']  ?? 5.5).toDouble(),
    phMax:  (setting['ph_max']  ?? 6.5).toDouble(),
    tdsMin: (setting['tds_min'] ?? 800).toDouble(),
    tdsMax: (setting['tds_max'] ?? 1200).toDouble(),
  );

  bool get phNormal  => ph  >= phMin  && ph  <= phMax;
  bool get tdsNormal => tds >= tdsMin && tds <= tdsMax;
  bool get ok        => phNormal && tdsNormal;
}

// ══════════════════════════════════════
// ROLE GLOBAL
// ══════════════════════════════════════
String _currentUser = '';
String _currentRole = ''; // 'admin' atau 'guest'

// ══════════════════════════════════════
// APP
// ══════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Hidroponik Monitor',
    theme: ThemeData(
      colorScheme: ColorScheme.dark(primary: AppColors.primary),
      scaffoldBackgroundColor: AppColors.bg,
    ),
    home: const SplashScreen(),
  );
}

// ══════════════════════════════════════
// SPLASH
// ══════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  String _msg = 'Menghubungkan ke server...';

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    await ApiService.detectConnection();
    setState(() => _msg = ApiService.isConnected
        ? 'Terhubung via ${ApiService.connectionType} ✓'
        : 'Offline — data tidak tersedia');
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF009966)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.eco, color: Colors.white, size: 40),
      ),
      const SizedBox(height: 20),
      const Text('HIDROPONIK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 2)),
      const Text('Monitoring & Kontrol Otomatis', style: TextStyle(fontSize: 13, color: AppColors.grey)),
      const SizedBox(height: 40),
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 16),
      Text(_msg, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
    ])),
  );
}

// ══════════════════════════════════════
// LOGIN PAGE
// ══════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('$tailscaleUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _userCtrl.text.trim(), 'password': _passCtrl.text.trim()}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _currentUser = data['username'];
        _currentRole = data['role'];
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        setState(() { _error = data['message'] ?? 'Login gagal'; });
      }
    } catch (e) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; });
    }
    setState(() { _loading = false; });
  }

  void _masukTamu() {
    _currentUser = 'Tamu';
    _currentRole = 'guest';
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🌿', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('HIDROPONIK MONITOR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Sistem Monitoring Hidroponik Dishub', style: TextStyle(fontSize: 12, color: AppColors.grey)),
            const SizedBox(height: 40),

            // ── FORM LOGIN ADMIN ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  const Text('LOGIN ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _userCtrl,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: Icon(Icons.person, color: AppColors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: Icon(Icons.lock, color: AppColors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: AppColors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('🔐 LOGIN SEBAGAI ADMIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── DIVIDER ──
            Row(children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('atau', style: TextStyle(fontSize: 11, color: AppColors.grey)),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ]),

            const SizedBox(height: 16),

            // ── TOMBOL TAMU ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _masukTamu,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.visibility, color: AppColors.grey, size: 16),
                  SizedBox(width: 8),
                  Text('MASUK SEBAGAI TAMU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.grey)),
                ]),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Tamu hanya dapat melihat data monitoring',
              style: TextStyle(fontSize: 10, color: AppColors.grey),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// MAIN PAGE - TAB
// Admin: Dashboard, Sensor, Pompa, Manual, Log, Pengaturan
// Tamu:  Dashboard, Sensor, Pompa, Log
// ══════════════════════════════════════
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _idx = 0;

  List<Widget> get _pages => [
    const DashboardPage(),
    const SensorPage(),
    const PompaPage(),
    if (_currentRole == 'admin') const ManualPage(),
    const LogPage(),
    if (_currentRole == 'admin') const PengaturanPage(),
  ];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.dashboard, size: 20), label: 'Dashboard'),
    const BottomNavigationBarItem(icon: Icon(Icons.water_drop, size: 20), label: 'Sensor'),
    const BottomNavigationBarItem(icon: Icon(Icons.settings_input_component, size: 20), label: 'Pompa'),
    if (_currentRole == 'admin') const BottomNavigationBarItem(icon: Icon(Icons.gamepad, size: 20), label: 'Manual'),
    const BottomNavigationBarItem(icon: Icon(Icons.history, size: 20), label: 'Log'),
    if (_currentRole == 'admin') const BottomNavigationBarItem(icon: Icon(Icons.settings, size: 20), label: 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pages[_idx],
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: _navItems,
      ),
    ),
  );
}

// ══════════════════════════════════════
// WIDGET HELPERS
// ══════════════════════════════════════
Widget buildTopBar(String title, String subtitle) => Container(
  color: AppColors.card,
  padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
  child: Row(children: [
    const Icon(Icons.eco, color: AppColors.primary, size: 20),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
      Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
    ])),
    // Badge role (Admin / Tamu)
    if (_currentRole.isNotEmpty)
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (_currentRole == 'admin' ? AppColors.primary : AppColors.grey).withOpacity(0.15),
          border: Border.all(color: (_currentRole == 'admin' ? AppColors.primary : AppColors.grey).withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _currentRole == 'admin' ? '👑 Admin' : '👁 Tamu',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: _currentRole == 'admin' ? AppColors.primary : AppColors.grey),
        ),
      ),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (ApiService.isConnected ? AppColors.primary : Colors.red).withOpacity(0.1),
        border: Border.all(color: (ApiService.isConnected ? AppColors.primary : Colors.red).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ApiService.isConnected ? AppColors.primary : Colors.red,
        )),
        const SizedBox(width: 5),
        Text(
          ApiService.isConnected ? ApiService.connectionType : 'Offline',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: ApiService.isConnected ? AppColors.primary : Colors.red),
        ),
      ]),
    ),
  ]),
);

Widget buildSensorCard(String label, double? value, bool normal, String unit, Color color) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
  child: Column(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
    Text(
      value != null ? value.toStringAsFixed(2) : '--',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: value == null ? AppColors.grey : (normal ? color : Colors.orange)),
    ),
    Text(unit, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (value == null ? AppColors.grey : (normal ? color : Colors.orange)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value == null ? 'No Data' : (normal ? '✓ Normal' : '⚠ Periksa'),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
          color: value == null ? AppColors.grey : (normal ? color : Colors.orange)),
      ),
    ),
  ]),
);

// ══════════════════════════════════════
// TAB 1 - DASHBOARD
// ══════════════════════════════════════
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardPage> {
  SensorData? _k1, _k2, _k3, _k4;
  Map<String, dynamic> _pompa   = {};
  Map<String, dynamic> _setting = {};
  String _mode    = 'semi';
  bool   _loading = true;
  Timer? _timer;

  @override void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final s       = await ApiService.getSensorLatest();
    final p       = await ApiService.getPompaStatus();
    final m       = await ApiService.getMode();
    final setting = await ApiService.getPengaturan();

    if (mounted) setState(() {
      _loading = false;
      _setting = setting;
      if (s['kotak_1'] != null) _k1 = SensorData.fromJsonWithBatas(s['kotak_1'], setting);
      if (s['kotak_2'] != null) _k2 = SensorData.fromJsonWithBatas(s['kotak_2'], setting);
      if (s['kotak_3'] != null) _k3 = SensorData.fromJsonWithBatas(s['kotak_3'], setting);
      if (s['kotak_4'] != null) _k4 = SensorData.fromJsonWithBatas(s['kotak_4'], setting);
      _pompa = p;
      _mode  = m['mode'] ?? 'semi';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('HIDROPONIK MONITOR', 'Sistem Monitoring & Kontrol Otomatis'),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: _fetch,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _buildModeBar(),
                const SizedBox(height: 12),
                _buildKotak1(),
                const SizedBox(height: 12),
                _buildKotakTanam(),
                const SizedBox(height: 12),
                _buildPompaStatus(),
              ]),
            ),
          )),
    ]),
  );

  Widget _buildModeBar() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      const Text('MODE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey)),
      const SizedBox(width: 10),
      ...[('auto','AUTO'), ('semi','SEMI'), ('manual','MANUAL')].map((e) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _mode == e.$1 ? AppColors.primary.withOpacity(0.2) : AppColors.bg,
            border: Border.all(color: _mode == e.$1 ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(e.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: _mode == e.$1 ? AppColors.primary : AppColors.grey)),
        ),
      )),
    ]),
  );

  Widget _buildKotak1() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Text('🧪 KOTAK 1 — MIXING TANK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        Spacer(),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: buildSensorCard('pH', _k1?.ph, _k1?.phNormal ?? false, 'pH', AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: buildSensorCard('TDS', _k1?.tds, _k1?.tdsNormal ?? false, 'ppm', AppColors.blue)),
      ]),
    ]),
  );

  Widget _buildKotakTanam() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('🌱 KOTAK TANAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey)),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: _buildKotakMini('Kotak 2', _k2)),
      const SizedBox(width: 8),
      Expanded(child: _buildKotakMini('Kotak 3', _k3)),
      const SizedBox(width: 8),
      Expanded(child: _buildKotakMini('Kotak 4', _k4)),
    ]),
  ]);

  Widget _buildKotakMini(String title, SensorData? sd) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: (sd?.ok ?? false) ? AppColors.border : Colors.orange.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(sd == null ? '--' : (sd.ok ? '✓' : '⚠'),
          style: TextStyle(fontSize: 11, color: sd == null ? AppColors.grey : (sd.ok ? AppColors.primary : Colors.orange))),
      ]),
      const SizedBox(height: 6),
      Text('pH: ${sd != null ? sd.ph.toStringAsFixed(2) : '--'}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: (sd?.phNormal ?? false) ? AppColors.primary : Colors.orange)),
      Text('TDS: ${sd != null ? '${sd.tds.toInt()} ppm' : '--'}',
        style: TextStyle(fontSize: 11,
          color: (sd?.tdsNormal ?? false) ? AppColors.blue : Colors.orange)),
    ]),
  );

  Widget _buildPompaStatus() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('⚙️ STATUS POMPA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey)),
      const SizedBox(height: 8),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
        children: ['pompa_1','pompa_2','pompa_3','pompa_4','pompa_5','pompa_6'].map((p) {
          final isOn = _pompa[p]?['status'] == 'on';
          return Container(
            decoration: BoxDecoration(
              color: isOn ? AppColors.primary.withOpacity(0.15) : AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isOn ? AppColors.primary.withOpacity(0.5) : AppColors.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(p.replaceAll('pompa_', 'P'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: isOn ? AppColors.primary : AppColors.grey)),
              Text(isOn ? 'ON' : 'OFF', style: TextStyle(fontSize: 9,
                color: isOn ? AppColors.primary : AppColors.grey)),
            ]),
          );
        }).toList(),
      ),
    ]),
  );
}



// ══════════════════════════════════════
// TAB 2 - SENSOR
// ══════════════════════════════════════
class SensorPage extends StatefulWidget {
  const SensorPage({super.key});
  @override State<SensorPage> createState() => _SensorState();
}

class _SensorState extends State<SensorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _kotakList  = ['kotak_1', 'kotak_2', 'kotak_3', 'kotak_4'];
  final _kotakLabel = ['Kotak 1', 'Kotak 2', 'Kotak 3', 'Kotak 4'];
  Map<String, dynamic> _sensor  = {};
  Map<String, dynamic> _setting = {};
  Map<String, List<dynamic>> _history = {};
  Map<String, dynamic> _weekly = {};
  bool _loading = true;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override void dispose() { _tabController.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final s       = await ApiService.getSensorLatest();
    final setting = await ApiService.getPengaturan();
    for (final k in _kotakList) {
      final h = await ApiService.getSensorHistory(k);
      final w = await ApiService.getSensorWeekly(k);
      if (mounted) setState(() {
        _loading  = false;
        _sensor   = s;
        _setting  = setting;
        _history[k] = h;
        _weekly[k]  = w;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('DETAIL SENSOR', 'pH, TDS, Water Level per Kotak'),
      Container(
        color: AppColors.card,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Kotak 1'), Tab(text: 'Kotak 2'), Tab(text: 'Kotak 3'), Tab(text: 'Kotak 4')],
        ),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: _kotakList.asMap().entries.map((e) =>
              _buildKotakDetail(e.value, _kotakLabel[e.key])
            ).toList(),
          )),
    ]),
  );

  Widget _buildKotakDetail(String kotak, String label) {
    final sd       = _sensor[kotak] != null ? SensorData.fromJsonWithBatas(_sensor[kotak], _setting) : null;
    final history  = _history[kotak] ?? [];
    final weekly   = _weekly[kotak]  ?? {};
    final isMixing = kotak == 'kotak_1';

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Row(children: [
                Text('${isMixing ? '🧪' : '🌱'} $label${isMixing ? ' — Mixing Tank' : ' — Kolam Tanam'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (isMixing && sd != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: sd.waterLevel ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sd.waterLevel ? Colors.green : Colors.orange),
                    ),
                    child: Text(sd.waterLevel ? '💧 Ada Air' : '⚠ Kosong',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: sd.waterLevel ? Colors.green : Colors.orange)),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: buildSensorCard('pH', sd?.ph, sd?.phNormal ?? false, 'pH', AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: buildSensorCard('TDS', sd?.tds, sd?.tdsNormal ?? false, 'ppm', AppColors.blue)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _buildGrafikCard('📈 GRAFIK pH (7 Hari)', history, 'ph', AppColors.primary),
          const SizedBox(height: 12),
          _buildGrafikCard('📈 GRAFIK TDS (7 Hari)', history, 'tds', AppColors.blue),
          const SizedBox(height: 12),
          _buildWeeklyCard(weekly),
        ]),
      ),
    );
  }

  Widget _buildGrafikCard(String title, List<dynamic> history, String field, Color color) {
    if (history.isEmpty) return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey)),
        const SizedBox(height: 20),
        const Center(child: Text('Belum ada data', style: TextStyle(fontSize: 11, color: AppColors.grey))),
        const SizedBox(height: 20),
      ]),
    );

    final values = history.map((e) => (e['${field}_avg'] as num).toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range  = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(maxVal.toStringAsFixed(1), style: const TextStyle(fontSize: 8, color: AppColors.grey)),
              Text(minVal.toStringAsFixed(1), style: const TextStyle(fontSize: 8, color: AppColors.grey)),
            ]),
            const SizedBox(width: 6),
            Expanded(child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: history.asMap().entries.map((e) {
                final val    = (e.value['${field}_avg'] as num).toDouble();
                final height = ((val - minVal) / range * 70) + 10;
                final label  = e.value['tanggal'].toString().substring(5);
                return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 7, color: color)),
                  const SizedBox(height: 2),
                  Container(width: 24, height: height, decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  )),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 7, color: AppColors.grey)),
                ]);
              }).toList(),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildWeeklyCard(Map<String, dynamic> weekly) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📊 RATA-RATA MINGGU INI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey)),
      const SizedBox(height: 10),
      if (weekly.isEmpty || weekly['message'] != null)
        const Center(child: Text('Belum ada data minggu ini', style: TextStyle(fontSize: 11, color: AppColors.grey)))
      else
        Column(children: [
          _buildWeeklyRow('pH rata-rata',  weekly['ph_avg']?.toStringAsFixed(2) ?? '--', AppColors.primary),
          _buildWeeklyRow('TDS rata-rata', '${weekly['tds_avg']?.toStringAsFixed(0) ?? '--'} ppm', AppColors.blue),
          const Divider(color: AppColors.border),
          _buildWeeklyRow('pH tertinggi',  weekly['ph_max']?.toStringAsFixed(2) ?? '--', Colors.orange),
          _buildWeeklyRow('pH terendah',   weekly['ph_min']?.toStringAsFixed(2) ?? '--', Colors.orange),
          const Divider(color: AppColors.border),
          _buildWeeklyRow('TDS tertinggi', '${weekly['tds_max']?.toStringAsFixed(0) ?? '--'} ppm', Colors.orange),
          _buildWeeklyRow('TDS terendah',  '${weekly['tds_min']?.toStringAsFixed(0) ?? '--'} ppm', Colors.orange),
          const Divider(color: AppColors.border),
          _buildWeeklyRow('Total data',    '${weekly['total_data'] ?? 0} data', AppColors.grey),
        ]),
    ]),
  );

  Widget _buildWeeklyRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ══════════════════════════════════════
// TAB 3 - POMPA STATUS
// ══════════════════════════════════════
class PompaPage extends StatefulWidget {
  const PompaPage({super.key});
  @override State<PompaPage> createState() => _PompaState();
}

class _PompaState extends State<PompaPage> {
  Map<String, dynamic> _pompa  = {};
  Map<String, dynamic> _sensor = {};
  bool _loading = true;
  Timer? _timer;

  final _pompaInfo = {
    'pompa_1': {'nama': 'Pompa 1', 'fungsi': 'Isi Air',    'kotak': 'kotak_1', 'icon': Icons.water_drop},
    'pompa_2': {'nama': 'Pompa 2', 'fungsi': 'pH Up',      'kotak': 'kotak_1', 'icon': Icons.arrow_upward},
    'pompa_3': {'nama': 'Pompa 3', 'fungsi': 'pH Down',    'kotak': 'kotak_1', 'icon': Icons.arrow_downward},
    'pompa_4': {'nama': 'Pompa 4', 'fungsi': 'Ke Kotak 2', 'kotak': 'kotak_2', 'icon': Icons.send},
    'pompa_5': {'nama': 'Pompa 5', 'fungsi': 'Ke Kotak 3', 'kotak': 'kotak_3', 'icon': Icons.send},
    'pompa_6': {'nama': 'Pompa 6', 'fungsi': 'Ke Kotak 4', 'kotak': 'kotak_4', 'icon': Icons.send},
  };

  @override void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final p = await ApiService.getPompaStatus();
    final s = await ApiService.getSensorLatest();
    if (mounted) setState(() { _loading = false; _pompa = p; _sensor = s; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('STATUS POMPA', 'Detail kondisi setiap pompa'),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: _pompaInfo.entries.map((e) => _buildPompaCard(e.key, e.value)).toList(),
            ),
          )),
    ]),
  );

  Widget _buildPompaCard(String key, Map<String, dynamic> info) {
    final isOn  = _pompa[key]?['status'] == 'on';
    final kotak = info['kotak'] as String;
    final sd    = _sensor[kotak] != null ? SensorData.fromJson(_sensor[kotak]) : null;
    final updAt = _pompa[key]?['updated_at'] ?? '--';
    final color = isOn ? AppColors.primary : AppColors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOn ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(info['icon'] as IconData, color: color, size: 18),
          const SizedBox(width: 8),
          Text(info['nama'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 8),
          Text('— ${info['fungsi']}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOn ? Colors.green.withOpacity(0.15) : AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOn ? Colors.green : AppColors.border),
            ),
            child: Text(isOn ? '● AKTIF' : '○ MATI',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isOn ? Colors.green : AppColors.grey)),
          ),
        ]),
        const Divider(color: AppColors.border, height: 16),
        Row(children: [
          Expanded(child: _buildInfoRow('Kotak', kotak.replaceAll('_', ' ').toUpperCase())),
          Expanded(child: _buildInfoRow('pH', sd != null ? sd.ph.toStringAsFixed(2) : '--')),
          Expanded(child: _buildInfoRow('TDS', sd != null ? '${sd.tds.toInt()} ppm' : '--')),
        ]),
        const SizedBox(height: 6),
        _buildInfoRow('Update terakhir', updAt.toString().length > 19 ? updAt.toString().substring(0, 19) : updAt.toString()),
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
    Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
  ]);
}

// ══════════════════════════════════════
// TAB 4 - MANUAL KONTROL (admin only)
// ══════════════════════════════════════
class ManualPage extends StatefulWidget {
  const ManualPage({super.key});
  @override State<ManualPage> createState() => _ManualState();
}

class _ManualState extends State<ManualPage> {
  Map<String, dynamic> _pompa = {};
  String _mode  = 'semi';
  bool _loading = true;
  Timer? _timer;

  final _pompaInfo = {
    'pompa_1': {'nama': 'Pompa 1', 'fungsi': 'Isi Air',    'kotak': 'Kotak 1'},
    'pompa_2': {'nama': 'Pompa 2', 'fungsi': 'pH Up',      'kotak': 'Kotak 1'},
    'pompa_3': {'nama': 'Pompa 3', 'fungsi': 'pH Down',    'kotak': 'Kotak 1'},
    'pompa_4': {'nama': 'Pompa 4', 'fungsi': 'Ke Kotak 2', 'kotak': 'Kotak 2'},
    'pompa_5': {'nama': 'Pompa 5', 'fungsi': 'Ke Kotak 3', 'kotak': 'Kotak 3'},
    'pompa_6': {'nama': 'Pompa 6', 'fungsi': 'Ke Kotak 4', 'kotak': 'Kotak 4'},
  };

  @override void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final p = await ApiService.getPompaStatus();
    final m = await ApiService.getMode();
    if (mounted) setState(() { _loading = false; _pompa = p; _mode = m['mode'] ?? 'semi'; });
  }

  Future<void> _setMode(String mode) async {
    await ApiService.setMode(mode);
    _fetch();
  }

  Future<void> _kontrolPompa(String pompa, String status) async {
    final result = await ApiService.kontrolPompa(pompa, status);
    if (!result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ ${result['message']}'),
        backgroundColor: Colors.red,
      ));
    }
    _fetch();
  }

  Future<void> _matikanSemua() async {
    for (final p in _pompaInfo.keys) {
      await ApiService.kontrolPompa(p, 'off');
    }
    _fetch();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('KONTROL MANUAL', 'ON/OFF pompa secara manual'),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _buildModeSelector(),
                const SizedBox(height: 12),
                _buildModeInfo(),
                const SizedBox(height: 12),
                ..._pompaInfo.entries.map((e) => _buildManualCard(e.key, e.value)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Matikan Semua?', style: TextStyle(color: AppColors.text)),
                      content: const Text('Semua pompa akan dimatikan.', style: TextStyle(color: AppColors.grey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                        TextButton(
                          onPressed: () { Navigator.pop(context); _matikanSemua(); },
                          child: const Text('Ya, Matikan', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.power_off, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('🔴 MATIKAN SEMUA POMPA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
                    ]),
                  ),
                ),
              ],
            ),
          )),
    ]),
  );

  Widget _buildModeSelector() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MODE SISTEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey)),
      const SizedBox(height: 10),
      Row(children: [
        ...[('auto','🤖 AUTO'), ('semi','⚡ SEMI'), ('manual','🎮 MANUAL')].map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _setMode(e.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _mode == e.$1 ? AppColors.primary.withOpacity(0.2) : AppColors.bg,
                  border: Border.all(color: _mode == e.$1 ? AppColors.primary : AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(e.$2, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _mode == e.$1 ? AppColors.primary : AppColors.grey)),
              ),
            ),
          ),
        )),
      ]),
    ]),
  );

  Widget _buildModeInfo() {
    String info = '';
    Color color = AppColors.grey;
    if (_mode == 'auto')   { info = '🤖 Mode AUTO: Otomatis penuh, manual dikunci'; color = AppColors.blue; }
    if (_mode == 'semi')   { info = '⚡ Mode SEMI: Otomatis tetap jalan, manual bisa override'; color = AppColors.primary; }
    if (_mode == 'manual') { info = '🎮 Mode MANUAL: Otomatis dimatikan, kontrol penuh manual'; color = Colors.orange; }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(info, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _buildManualCard(String key, Map<String, dynamic> info) {
    final isOn     = _pompa[key]?['status'] == 'on';
    final isLocked = _mode == 'auto';
    bool p2On = _pompa['pompa_2']?['status'] == 'on';
    bool p3On = _pompa['pompa_3']?['status'] == 'on';
    bool locked = false;
    String lockMsg = '';
    if (key == 'pompa_2' && p3On) { locked = true; lockMsg = '🔒 Pompa 3 aktif'; }
    if (key == 'pompa_3' && p2On) { locked = true; lockMsg = '🔒 Pompa 2 aktif'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOn ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info['nama'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text('${info['fungsi']} — ${info['kotak']}', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOn ? Colors.green.withOpacity(0.15) : AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOn ? Colors.green : AppColors.border),
            ),
            child: Text(isOn ? '● ON' : '○ OFF',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isOn ? Colors.green : AppColors.grey)),
          ),
        ]),
        if (isLocked || locked) ...[
          const SizedBox(height: 6),
          Text(isLocked ? '🔒 Mode AUTO aktif, manual dikunci' : lockMsg,
            style: const TextStyle(fontSize: 10, color: Colors.orange)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: (isLocked || locked) ? null : () => _kontrolPompa(key, 'on'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (!isLocked && !locked) ? Colors.green.withOpacity(0.15) : AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (!isLocked && !locked) ? Colors.green : AppColors.border),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.play_arrow, color: (!isLocked && !locked) ? Colors.green : AppColors.grey, size: 16),
                const SizedBox(width: 4),
                Text('ON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: (!isLocked && !locked) ? Colors.green : AppColors.grey)),
              ]),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: isLocked ? null : () => _kontrolPompa(key, 'off'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !isLocked ? Colors.red.withOpacity(0.15) : AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: !isLocked ? Colors.red : AppColors.border),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.stop, color: !isLocked ? Colors.red : AppColors.grey, size: 16),
                const SizedBox(width: 4),
                Text('OFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: !isLocked ? Colors.red : AppColors.grey)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════
// TAB 5 - LOG
// ══════════════════════════════════════
class LogPage extends StatefulWidget {
  const LogPage({super.key});
  @override State<LogPage> createState() => _LogState();
}

class _LogState extends State<LogPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _logs = [];
  String _filterTrigger = '';
  bool _loading = true;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override void dispose() { _tabController.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final l = await ApiService.getLog(limit: 50, trigger: _filterTrigger.isEmpty ? null : _filterTrigger);
    if (mounted) setState(() { _loading = false; _logs = l; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('LOG AKTIVITAS', 'Riwayat pompa & rata-rata mingguan'),
      Container(
        color: AppColors.card,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: '📋 Log Aktivitas'), Tab(text: '📊 Rata-rata Mingguan')],
        ),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: [_buildLogTab(), _buildWeeklyTab()],
          )),
    ]),
  );

  Widget _buildLogTab() => Column(children: [
    Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        const Text('Filter: ', style: TextStyle(fontSize: 11, color: AppColors.grey)),
        ...[('','Semua'), ('auto','Auto'), ('manual','Manual')].map((e) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () { setState(() => _filterTrigger = e.$1); _fetch(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _filterTrigger == e.$1 ? AppColors.primary.withOpacity(0.2) : AppColors.bg,
                border: Border.all(color: _filterTrigger == e.$1 ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(e.$2, style: TextStyle(fontSize: 10,
                color: _filterTrigger == e.$1 ? AppColors.primary : AppColors.grey)),
            ),
          ),
        )),
      ]),
    ),
    Expanded(child: RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _fetch,
      child: _logs.isEmpty
        ? const Center(child: Text('Belum ada log', style: TextStyle(color: AppColors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _logs.length,
            itemBuilder: (context, i) {
              final log    = _logs[i];
              final isOn   = log['aksi'] == 'on';
              final isAuto = log['trigger_type'] == 'auto';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isOn ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isOn ? Icons.power : Icons.power_off,
                      color: isOn ? Colors.green : Colors.red, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(log['pompa'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isOn ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(isOn ? 'ON' : 'OFF',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: isOn ? Colors.green : Colors.red)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAuto ? AppColors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(isAuto ? 'Auto' : 'Manual',
                          style: TextStyle(fontSize: 9, color: isAuto ? AppColors.blue : Colors.orange)),
                      ),
                    ]),
                    Text(log['keterangan'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                    Text(log['timestamp']?.toString().substring(0, 19) ?? '--',
                      style: const TextStyle(fontSize: 9, color: AppColors.grey)),
                  ])),
                ]),
              );
            },
          ),
    )),
  ]);

  Widget _buildWeeklyTab() {
    final kotakList  = ['kotak_1', 'kotak_2', 'kotak_3', 'kotak_4'];
    final kotakLabel = ['Kotak 1 (Mixing)', 'Kotak 2', 'Kotak 3', 'Kotak 4'];
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _fetch,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait(kotakList.map((k) => ApiService.getSensorWeekly(k))),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: 4,
            itemBuilder: (context, i) {
              final w = snap.data![i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kotakLabel[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const Divider(color: AppColors.border),
                  if (w.isEmpty || w['message'] != null)
                    const Text('Belum ada data', style: TextStyle(fontSize: 11, color: AppColors.grey))
                  else
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _weeklyItem('pH rata-rata', w['ph_avg']?.toStringAsFixed(2) ?? '--', AppColors.primary),
                        _weeklyItem('pH min',       w['ph_min']?.toStringAsFixed(2) ?? '--', Colors.orange),
                        _weeklyItem('pH max',       w['ph_max']?.toStringAsFixed(2) ?? '--', Colors.orange),
                      ])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _weeklyItem('TDS rata-rata', '${w['tds_avg']?.toStringAsFixed(0) ?? '--'} ppm', AppColors.blue),
                        _weeklyItem('TDS min',       '${w['tds_min']?.toStringAsFixed(0) ?? '--'} ppm', Colors.orange),
                        _weeklyItem('TDS max',       '${w['tds_max']?.toStringAsFixed(0) ?? '--'} ppm', Colors.orange),
                      ])),
                    ]),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _weeklyItem(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ══════════════════════════════════════
// TAB 6 - PENGATURAN (admin only)
// ══════════════════════════════════════
class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});
  @override State<PengaturanPage> createState() => _PengaturanState();
}

class _PengaturanState extends State<PengaturanPage> {
  final _phMin          = TextEditingController(text: '5.5');
  final _phMax          = TextEditingController(text: '6.5');
  final _tdsMin         = TextEditingController(text: '800');
  final _tdsMax         = TextEditingController(text: '1200');
  final _intervalMixing = TextEditingController(text: '360');
  final _intervalKotak  = TextEditingController(text: '180');
  final _faktorPh       = TextEditingController(text: '6.0');
  final _faktorTds      = TextEditingController(text: '3.0');
  bool _saving = false;
  String _mode = 'semi';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await ApiService.getPengaturan();
    final m = await ApiService.getMode();
    if (mounted && d.isNotEmpty) setState(() {
      _phMin.text          = (d['ph_min']          ?? 5.5).toString();
      _phMax.text          = (d['ph_max']          ?? 6.5).toString();
      _tdsMin.text         = (d['tds_min']         ?? 800).toString();
      _tdsMax.text         = (d['tds_max']         ?? 1200).toString();
      _intervalMixing.text = (d['interval_mixing'] ?? 360).toString();
      _intervalKotak.text  = (d['interval_kotak']  ?? 180).toString();
      _faktorPh.text       = (d['faktor_ph']       ?? 6.0).toString();
      _faktorTds.text      = (d['faktor_tds']      ?? 3.0).toString();
      _mode = m['mode'] ?? 'semi';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(children: [
      buildTopBar('PENGATURAN', 'Konfigurasi sistem hidroponik'),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _buildSection('🌡️ BATAS pH & TDS', [
            _buildRow('pH Minimum', 'Pompa pH Up aktif jika pH di bawah ini', _phMin),
            _buildRow('pH Maksimum', 'Pompa pH Down aktif jika pH di atas ini', _phMax),
            const Divider(color: AppColors.border),
            _buildRow('TDS Minimum (ppm)', 'Batas bawah nutrisi normal', _tdsMin),
            _buildRow('TDS Maksimum (ppm)', 'Batas atas nutrisi normal', _tdsMax),
          ]),
          const SizedBox(height: 12),
          _buildSection('⏱️ JADWAL PENGECEKAN', [
            _buildRow('Interval Mixing Tank (menit)', 'Default 360 = 6 jam. Ganti ke 1 untuk demo', _intervalMixing),
            _buildRow('Interval Kotak Tanam (menit)', 'Default 180 = 3 jam. Ganti ke 1 untuk demo', _intervalKotak),
          ]),
          const SizedBox(height: 12),
          _buildSection('🔧 KALIBRASI POMPA', [
            _buildRow('Faktor pH', 'Selisih pH × faktor = durasi pompa (detik)', _faktorPh),
            _buildRow('Faktor TDS', 'Selisih TDS × faktor = durasi pompa (detik)', _faktorTds),
          ]),
          const SizedBox(height: 12),
          _buildSection('🌐 INFO SERVER', [
            _buildInfoRow('URL', ApiService.baseUrl),
            _buildInfoRow('Status', ApiService.isConnected ? '● Online' : '○ Offline'),
            _buildInfoRow('Koneksi', ApiService.connectionType),
            _buildInfoRow('Mode', _mode.toUpperCase()),
            _buildInfoRow('Login sebagai', _currentUser),
          ]),
          const SizedBox(height: 12),
          _buildSection('📋 INFO OTOMASI', [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('• Data sensor dikirim ESP32 setiap 5 detik', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('• pH di luar range → pompa pH Up/Down nyala otomatis', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('• TDS kurang → pompa isi air nyala otomatis', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('• Mode SEMI: otomatis + manual bisa override', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: _saving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('💾 SIMPAN', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              ),
              child: const Text('↺ RESET', style: TextStyle(color: AppColors.grey)),
            ),
          ]),
        ]),
      )),
    ]),
  );

  Widget _buildSection(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );

  Widget _buildRow(String label, String sub, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
        Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
      ])),
      SizedBox(width: 80, child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF142840),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: AppColors.border)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      )),
    ]),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
    ]),
  );

  void _reset() {
    _phMin.text          = '5.5';
    _phMax.text          = '6.5';
    _tdsMin.text         = '800';
    _tdsMax.text         = '1200';
    _intervalMixing.text = '360';
    _intervalKotak.text  = '180';
    _faktorPh.text       = '6.0';
    _faktorTds.text      = '3.0';
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    final ok = await ApiService.simpanPengaturan({
      'ph_min'         : double.tryParse(_phMin.text)       ?? 5.5,
      'ph_max'         : double.tryParse(_phMax.text)       ?? 6.5,
      'tds_min'        : int.tryParse(_tdsMin.text)         ?? 800,
      'tds_max'        : int.tryParse(_tdsMax.text)         ?? 1200,
      'interval_mixing': int.tryParse(_intervalMixing.text) ?? 360,
      'interval_kotak' : int.tryParse(_intervalKotak.text)  ?? 180,
      'faktor_ph'      : double.tryParse(_faktorPh.text)    ?? 6.0,
      'faktor_tds'     : double.tryParse(_faktorTds.text)   ?? 3.0,
    });
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ Pengaturan disimpan!' : '❌ Gagal menyimpan'),
      backgroundColor: ok ? AppColors.primary : Colors.red,
    ));
  }
}