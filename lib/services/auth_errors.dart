import 'package:firebase_auth/firebase_auth.dart';

/// Mensajes de error de autenticación pensados para el cliente.
///
/// No muestran el error técnico de Firebase, y en el login no revelan
/// si el correo existe o no (evita que alguien averigüe qué cuentas hay).
String authErrorMessage(Object error, {bool registro = false}) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos';
      case 'invalid-email':
        return 'El correo no es válido';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-disabled':
        return 'Esta cuenta está desactivada';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
      case 'popup-blocked':
        return 'El navegador bloqueó la ventana de Google. Permite las ventanas emergentes e inténtalo otra vez.';
      case 'account-exists-with-different-credential':
        return 'Ese correo ya tiene una cuenta. Entra con tu correo y contraseña.';
      case 'operation-not-allowed':
      case 'unauthorized-domain':
        return 'El acceso con Google no está disponible ahora mismo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
    }
  }
  return registro
      ? 'No se pudo crear la cuenta. Inténtalo de nuevo.'
      : 'No se pudo iniciar sesión. Inténtalo de nuevo.';
}
