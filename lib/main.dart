import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'reservas_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAQFJoAVe--vSicgSIOfKW6jgd_z0DImfc",
      authDomain: "alpina-f38a0.firebaseapp.com",
      projectId: "alpina-f38a0",
      storageBucket: "alpina-f38a0.appspot.com",
      messagingSenderId: "289526242558",
      appId: "1:289526242558:web:deefcdd5c7d540900559af",
      measurementId: "G-H8TCSE152Q"
    ),
  );
  runApp(const AlpinaApp());
}

class AlpinaApp extends StatelessWidget {
  const AlpinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Configuración en español
      ],
      title: 'Gestión de Reservas',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ReservasScreen(),
    );
  }
}