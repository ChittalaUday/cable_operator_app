import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with error handling
    await Firebase.initializeApp().catchError((error) {
      debugPrint('Firebase initialization error: $error');
    });

    // Run the app with error boundary
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Show error UI if needed
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cable Operator App',
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          debugPrint('Error caught by error boundary: ${details.exception}');
          return Material(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  'An error occurred. Please restart the app.',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}
