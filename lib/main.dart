import 'package:flutter/material.dart';

import 'data/ipconfig/wifi_api_config.dart';
import 'data/dance_database.dart';
import 'screens/admin_server_screen.dart';
import 'screens/dance_home_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/reports_screen.dart';

// Abraham Espinoza Vargas expone: inicio de la app, identidad visual y menu.
const _ink = Color(0xFF202928);
const _paper = Color(0xFFF5F3EC);
const _green = Color(0xFF176B58);
const _coral = Color(0xFFDF7359);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WifiApiConfig.load();
  final database = DanceDatabase();
  runApp(DanceEvaluationApp(database: database));
}

class DanceEvaluationApp extends StatelessWidget {
  const DanceEvaluationApp({super.key, required this.database});

  final DanceDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulso · Evaluación de baile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          primary: _green,
          secondary: _coral,
          surface: Colors.white,
          onSurface: _ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCDDD5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCDDD5)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E3DC)),
          ),
        ),
      ),
      home: DanceShell(database: database),
    );
  }
}

class DanceShell extends StatefulWidget {
  const DanceShell({super.key, required this.database});

  final DanceDatabase database;

  @override
  State<DanceShell> createState() => _DanceShellState();
}

class _DanceShellState extends State<DanceShell> {
  int _selectedIndex = 0;
  int _refreshKey = 0;

  void _onSaved() {
    setState(() {
      _refreshKey++;
      _selectedIndex = 2;
    });
  }

  void _openServerConfig() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminServerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DanceHomeScreen(
        database: widget.database,
        refreshKey: _refreshKey,
        onStartEvaluation: () => setState(() => _selectedIndex = 1),
        onOpenReports: () => setState(() => _selectedIndex = 2),
        onOpenServerConfig: _openServerConfig,
      ),
      EvaluationScreen(database: widget.database, onSaved: _onSaved),
      ReportsScreen(database: widget.database, refreshKey: _refreshKey),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: GestureDetector(
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminServerScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PULSO',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                        Text(
                          'EVALUACIÓN DE BAILE',
                          style: TextStyle(
                            color: Color(0xFF6F7772),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Configuración del servidor',
                      onPressed: _openServerConfig,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    IconButton(
                      tooltip: 'Inicio',
                      onPressed: () => setState(() => _selectedIndex = 0),
                      icon: const Icon(Icons.home_outlined),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
                child: IndexedStack(index: _selectedIndex, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCEBE4),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_rounded),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Evaluar',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_rounded),
            selectedIcon: Icon(Icons.query_stats_rounded),
            label: 'Consultas',
          ),
        ],
      ),
    );
  }
}
