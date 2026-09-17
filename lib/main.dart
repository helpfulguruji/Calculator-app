import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ads_service.dart';
import 'widgets/banner_ad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.instance.initialize();
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});
  @override State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _mode = ThemeMode.system;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _mode = ThemeMode.values.firstWhere((e) => e.name == (p.getString('theme') ?? 'system'), orElse: () => ThemeMode.system);
      _haptics = p.getBool('haptics') ?? true;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', mode.name);
    if (mounted) setState(() => _mode = mode);
  }

  Future<void> _setHaptics(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('haptics', value);
    if (mounted) setState(() => _haptics = value);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    final light = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    final dark = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'All-in-One Calculator',
      themeMode: _mode,
      theme: ThemeData(useMaterial3: true, colorScheme: light, scaffoldBackgroundColor: const Color(0xFFF7F7FB), cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: dark, scaffoldBackgroundColor: const Color(0xFF0F1015), cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0)),
      home: HomeScreen(haptics: _haptics, onHapticsChanged: _setHaptics, themeMode: _mode, onThemeChanged: _setTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool haptics;
  final ValueChanged<bool> onHapticsChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  const HomeScreen({super.key, required this.haptics, required this.onHapticsChanged, required this.themeMode, required this.onThemeChanged});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _pages = const [CalculatorPage(), FinancePage(), ConverterPage(), ToolsPage()];
  final _titles = const ['Calculator', 'Finance', 'Convert', 'Tools'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index], style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: 'Settings', onPressed: () => _showSettings(context), icon: const Icon(Icons.settings_outlined))],
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomSheet: const BannerAdWidget(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Calculator'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finance'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), selectedIcon: Icon(Icons.swap_horiz), label: 'Convert'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Tools'),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheet) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          SwitchListTile(value: widget.haptics, onChanged: (v) { widget.onHapticsChanged(v); setSheet(() {}); }, title: const Text('Haptic feedback'), subtitle: const Text('Gentle feedback on calculator keys'), contentPadding: EdgeInsets.zero),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Theme'), subtitle: Text(widget.themeMode.name[0].toUpperCase() + widget.themeMode.name.substring(1)), trailing: DropdownButton<ThemeMode>(value: widget.themeMode, underline: const SizedBox.shrink(), items: const [DropdownMenuItem(value: ThemeMode.system, child: Text('System')), DropdownMenuItem(value: ThemeMode.light, child: Text('Light')), DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark'))], onChanged: (v) { if (v != null) { widget.onThemeChanged(v); setSheet(() {}); } })),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy-first design'), subtitle: Text('Calculations stay on your device. No account is required.')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.tune), title: const Text('Ad privacy options'), subtitle: const Text('Manage available advertising consent choices.'), onTap: () => AdsService.instance.showPrivacyOptions()),
          const SizedBox(height: 4),
          const Text('All-in-One Calculator • v1.5.1', style: TextStyle(fontSize: 12)),
        ]),
      )),
    );
