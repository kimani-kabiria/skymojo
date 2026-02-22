import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skymojo/config/supabase_config.dart';
import 'package:skymojo/auth/auth_gate.dart';
import 'package:skymojo/services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables first
  try {
    await dotenv.load(fileName: "assets/.env");
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Error loading environment variables: $e');
    // Fallback to root .env for development
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded from root successfully');
    } catch (e2) {
      print('Error loading environment variables from root: $e2');
    }
  }
  
  await SupabaseConfig.initialize();
  await GoogleAuthService.initialize();
  runApp(const SkyMojoApp());
}

class SkyMojoApp extends StatelessWidget {
  const SkyMojoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkyMojo',
      theme: ThemeData(
        fontFamily: 'Bellota'
      ),
      home: AnimatedSplashScreen(
        splash: Image.asset('assets/logo.png'),
        nextScreen: const AuthGate(),
        pageTransitionType: PageTransitionType.rightToLeftWithFade,
      ),
    );
  }
}
