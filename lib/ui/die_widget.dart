import 'dart:math';
import 'package:flutter/material.dart';

/// A white die with pseudo-3D thickness; tumbles while [t] runs 0 -> 1.
class DieView extends StatelessWidget {
  const DieView({super.key, required this.value, required this.size,
      required this.t, required this.index, this.dimmed = false});
  final int value, index;
  final double size;
  final Animation<double> t;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Die ${index + 1}: $value',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: t,
          builder: (_, child) {
            final p = Curves.easeOutCubic.transform(t.value);
            final a = (1 - p) * 2 * pi * (2 + index % 2);
            final lift = -sin(t.value * pi) * size * 0.35;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..translate(0.0, lift)
                ..rotateX(a)
                ..rotateY(a * 0.7)
                ..rotateZ(a * 0.3),
              child: child,
            );
          },
          child: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: SizedBox(
              width: size, height: size + 6,
              child: Stack(children: [
                Positioned(top: 6, left: 0, right: 0, bottom: 0,
                  child: DecoratedBox(decoration: BoxDecoration(
                    color: const Color(0xFFB9C0CC),
                    borderRadius: BorderRadius.circular(size * 0.2),
                    boxShadow: const [BoxShadow(color: Color(0x66000000),
                        blurRadius: 12, offset: Offset(0, 6))]))),
                Positioned(top: 0, left: 0, right: 0, height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.2),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFE6EAF0)])),
                    child: CustomPaint(painter: _PipPainter(value)))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter(this.v);
  final int v;
  static const l = .28, r = .72, m = .5;
  static const _map = <int, List<Offset>>{
    1: [Offset(m, m)],
    2: [Offset(l, l), Offset(r, r)],
    3: [Offset(l, l), Offset(m, m), Offset(r, r)],
    4: [Offset(l, l), Offset(r, l), Offset(l, r), Offset(r, r)],
    5: [Offset(l, l), Offset(r, l), Offset(m, m), Offset(l, r), Offset(r, r)],
    6: [Offset(l, l), Offset(r, l), Offset(l, m), Offset(r, m),
        Offset(l, r), Offset(r, r)],
  };

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF111827);
    for (final o in _map[v]!) {
      c.drawCircle(Offset(o.dx * s.width, o.dy * s.height), s.width * 0.085, p);
    }
  }

  @override
  bool shouldRepaint(_PipPainter o) => o.v != v;
}
