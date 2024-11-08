import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'reservas_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
///import 'initialize_habitaciones.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    ///await initializeHabitaciones(); // Eliminar despues de ejecutar por primera vez
    runApp(const AlpinaApp());
  } catch (e, stackTrace) {
    print('Error durante la inicialización de Firebase: $e');
    print('Stack trace: $stackTrace');
  }
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