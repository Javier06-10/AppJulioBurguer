import 'package:flutter/material.dart';

class OrderProgressWidget extends StatelessWidget {
  final double progress;
  final int minutosRestantes;

  const OrderProgressWidget({
    super.key,
    required this.progress,
    required this.minutosRestantes,
  });

  @override
  Widget build(BuildContext context) {
    final retrasado = progress >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          retrasado
              ? '⚠️ Pedido retrasado'
              : '⏳ Preparando pedido',
          style: TextStyle(
            color: retrasado ? Colors.red : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          minHeight: 10,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(
            retrasado ? Colors.red : Colors.orange,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          retrasado
              ? 'Retraso de ${minutosRestantes.abs()} min'
              : 'Tiempo restante: $minutosRestantes min',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
