import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización con tus credenciales WEB reales
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB3vNSJQg-2Hw47palDPvW5W492WoqHrfs",
      authDomain: "loginauth-41ec3.firebaseapp.com",
      projectId: "loginauth-41ec3",
      storageBucket: "loginauth-41ec3.firebasestorage.app",
      messagingSenderId: "953854823291",
      appId: "1:953854823291:web:d8d0b152b2116afaa24bde",
      measurementId: "G-M6N8FP96T7",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Auth Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const ChatListScreen(); // <-- ¡Asegúrate de tener esto!
          }
          return const LoginScreen();
        },
      ),
    );
  }
}