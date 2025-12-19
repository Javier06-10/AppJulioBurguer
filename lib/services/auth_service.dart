import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// USUARIO ACTUAL
  User? get currentUser => _auth.currentUser;
}
