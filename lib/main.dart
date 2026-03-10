import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:focus_planner_app/features/auth/login_page.dart';
import 'package:focus_planner_app/features/tasks/presentation/home_task_page.dart';
import 'package:focus_planner_app/features/tasks/presentation/profile_page.dart';
import 'package:focus_planner_app/features/settings/presentation/settings_page.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/tasks/presentation/auth_gate.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FocusPlannerApp());
}

class FocusPlannerApp extends StatelessWidget {
  const FocusPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Focus Timer App',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            home: const AuthGate(),  // ✅ ใช้ AuthGate เป็น default

            // ✅ เพิ่ม named routes ทั้งหมด
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const HomeTaskPage(),
              '/profile': (context) => const ProfilePage(),
              '/settings': (context) => const SettingsPage(),
            },

            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}