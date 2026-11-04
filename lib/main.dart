import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_julioburguer/pages/cart_screen.dart';
import 'package:flutter_julioburguer/pages/profile_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es');
  runApp(MyApp(initialRoute: await _initialRoute()));
}

/// Si ya hay sesión guardada (p. ej. al abrir la app instalada), entra directo al menú.
Future<String> _initialRoute() async {
  final user = await FirebaseAuth.instance.authStateChanges().first;
  return user == null ? '/login' : '/products';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: El Provider debe envolver MaterialApp
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: "D'Julio Burger Pizza",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        initialRoute: initialRoute,
        builder: (context, child) => _AppFrame(child: child!),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/products': (context) => const ProductsScreen(),

          '/cart': (context) => const CartScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
      ),
    );
  }
}

/// En pantallas anchas (navegador de escritorio) muestra la app como una
/// columna centrada tipo móvil, en vez de estirarla.
class _AppFrame extends StatelessWidget {
  final Widget child;
  const _AppFrame({required this.child});

  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= _maxWidth + 120) return child;

    return ColoredBox(
      color: const Color(0xFF070606),
      child: Center(
        child: Container(
          width: _maxWidth,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.border),
            ),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40)],
          ),
          child: MediaQuery(
            data: mq.copyWith(size: Size(_maxWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
