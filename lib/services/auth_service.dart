import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// REGISTRO
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
  }) async {
    // 1️⃣ Crear usuario en Firebase Auth
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2️⃣ Guardar datos adicionales en Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'nombre': nombre,
      'direccion': direccion,
      'email': email,
      'rol': 'cliente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Enlace para verificar el correo (necesario para hacer pedidos)
    try {
      await cred.user!.sendEmailVerification();
    } catch (_) {
      // Si falla, se puede reenviar al momento de pedir.
    }
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// LOGIN CON GOOGLE
  ///
  /// Devuelve `false` si la persona cerró la ventana de Google sin elegir
  /// cuenta. La primera vez crea su perfil de cliente en Firestore.
  Future<bool> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});

    final UserCredential cred;
    try {
      cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      const cancelled = {
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
        'canceled',
      };
      if (cancelled.contains(e.code)) return false;
      rethrow;
    }

    await _ensureClientProfile(cred.user!);
    return true;
  }

  /// Crea el documento del usuario si aún no existe (primer acceso con Google).
  Future<void> _ensureClientProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final nombre = (user.displayName ?? '').trim();
    await ref.set({
      'uid': user.uid,
      'nombre': nombre.length > 100 ? nombre.substring(0, 100) : nombre,
      'direccion': '',
      'email': user.email ?? '',
      'rol': 'cliente',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// USUARIO ACTUAL
  User? get currentUser => _auth.currentUser;
}
