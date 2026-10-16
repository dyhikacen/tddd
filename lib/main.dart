import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'providers/budget_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HoMnyApp());
}

/// Root application widget for HoMny (Manajemen Uang Kos).
class HoMnyApp extends StatefulWidget {
  final BudgetProvider? provider;

  const HoMnyApp({super.key, this.provider});

  @override
  State<HoMnyApp> createState() => _HoMnyAppState();
}

/// Backwards compatibility alias for tests and legacy references
typedef MamnyApp = HoMnyApp;

class _HoMnyAppState extends State<HoMnyApp> {
  late final BudgetProvider _budgetProvider;

  @override
  void initState() {
    super.initState();
    _budgetProvider = widget.provider ?? BudgetProvider();
    _budgetProvider.initialize();
  }

  @override
  void dispose() {
    // Only dispose if we created it internally
    if (widget.provider == null) {
      _budgetProvider.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoMny',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: DashboardScreen(provider: _budgetProvider),
    );
  }
}
