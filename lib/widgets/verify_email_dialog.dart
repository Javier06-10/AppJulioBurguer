import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Comprueba que el correo del cliente esté verificado antes de pedir.
/// Si no lo está, muestra un diálogo para reenviar el enlace y confirmar.
/// Devuelve true cuando ya puede pedir.
Future<bool> ensureVerifiedEmail(BuildContext context) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return false;

  if (!user.emailVerified) {
    await user.reload();
  }
  if (auth.currentUser?.emailVerified == true) {
    await _refreshTokenIfNeeded(auth.currentUser!);
    return true;
  }
  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _VerifyEmailDialog(),
  );
  return ok == true;
}

/// Las reglas leen `email_verified` del token; tras verificar hay que renovarlo.
Future<void> _refreshTokenIfNeeded(User user) async {
  final token = await user.getIdTokenResult();
  if (token.claims?['email_verified'] != true) {
    await user.getIdToken(true);
  }
}

class _VerifyEmailDialog extends StatefulWidget {
  const _VerifyEmailDialog();

  @override
  State<_VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<_VerifyEmailDialog> {
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await _user?.sendEmailVerification();
      _show('Te enviamos el enlace a ${_user?.email}. Revisa también el correo no deseado.');
    } on FirebaseAuthException catch (e) {
      _show(
        e.code == 'too-many-requests'
            ? 'Ya te enviamos varios correos. Espera unos minutos.'
            : 'No se pudo enviar el correo. Inténtalo de nuevo.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await _user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified == true) {
        await _refreshTokenIfNeeded(user!);
        if (mounted) Navigator.pop(context, true);
        return;
      }
      _show('Todavía no aparece verificado. Abre el enlace del correo y vuelve a intentarlo.',
          error: true);
    } catch (_) {
      _show('Sin conexión. Revisa tu internet.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String msg, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _messageIsError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.mark_email_unread_outlined,
          color: AppColors.primary, size: 36),
      title: const Text('Verifica tu correo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Para hacer pedidos necesitamos confirmar que el correo '
            '${_user?.email ?? ''} es tuyo. Abre el enlace que te enviamos '
            'y luego toca "Ya lo verifiqué".',
            textAlign: TextAlign.center,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _messageIsError ? AppColors.danger : AppColors.success,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _resend,
          child: const Text('Reenviar correo'),
        ),
        FilledButton(
          onPressed: _busy ? null : _check,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ya lo verifiqué'),
        ),
      ],
    );
  }
}
