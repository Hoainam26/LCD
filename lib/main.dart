import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state_service.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appStateService = AppStateService();
  await appStateService.initialize();
  
  runApp(
    ChangeNotifierProvider.value(
      value: appStateService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LCD KHOA CNTT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}