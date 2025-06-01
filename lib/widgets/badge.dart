import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  final Widget child;
  final Widget label;

  const Badge({super.key, required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        child,
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Center(
              child: label,
            ),
          ),
        ),
      ],
    );
  }
}