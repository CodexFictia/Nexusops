import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'screens/login_screen.dart';
import 'screens/executive_screen.dart';
import 'screens/am_screen.dart';
import 'screens/ch_screen.dart';
import 'core/models.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const NexusOpsApp(),
    ),
  );
}

class NexusOpsApp extends StatelessWidget {
  const NexusOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Ops',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) return const LoginScreen();
          switch (auth.currentUser!.role) {
            case UserRole.executive:
              return const ExecutiveShell();
            case UserRole.accountManager:
              return const AccountManagerShell();
            case UserRole.centreHead:
              return const CentreHeadShell();
          }
        },
      ),
    );
  }
}
