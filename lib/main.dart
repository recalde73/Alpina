import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'reservas_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Usa las opciones generadas para Firebase
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