import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_julioburguer/pages/cart_screen.dart';
import 'package:flutter_julioburguer/pages/profile_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/admin/admin_shell.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/products_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es');
  runApp(const MyApp());
}
final categoriaRef = FirebaseFirestore.instance
    .collection('categories')
    .doc('b5cxNnNwBfmVQUWQUhib');


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: El Provider debe envolver MaterialApp
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: "D'Julio Burger Pizza",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/products': (context) =>  ProductsScreen(
                categoryRef: categoriaRef,
                categoryName: '',
  
          ),

          '/cart': (context) => const CartScreen(),
           '/profile': (_) => const ProfileScreen(),
          '/admin': (_) => const AdminShell(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        },
      ),
    );
  }
}