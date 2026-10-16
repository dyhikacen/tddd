import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'providers/budget_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MamnyApp());
}

/// Root application widget for Mamny (Manajemen Uang Kos).
class MamnyApp extends StatefulWidget {
  final BudgetProvider? provider;

  const MamnyApp({super.key, this.provider});

  @override
  State<MamnyApp> createState() => _MamnyAppState();
}

class _MamnyAppState extends State<MamnyApp> {
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
      title: 'Manajemen Uang Kos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: DashboardScreen(provider: _budgetProvider),
    );
  }
}
