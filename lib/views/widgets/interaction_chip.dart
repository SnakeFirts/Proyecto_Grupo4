import 'package:flutter/material.dart';

class InteractionChip extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap; // Solo dejamos onTap

  const InteractionChip({
    super.key,
    required this.titulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap, // Eliminamos el "alSeleccionar" que causaba conflicto
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: seleccionado
                ? const Color(0xffEEF4FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionado
                  ? const Color.fromARGB(255, 59, 130, 246)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                color: seleccionado
                    ? const Color.fromARGB(255, 59, 130, 246)
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: seleccionado
                      ? const Color.fromARGB(255, 59, 130, 246)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}