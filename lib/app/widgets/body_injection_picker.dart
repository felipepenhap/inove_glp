import 'package:flutter/material.dart';

import '../../core/models/injection_site.dart';
import '../../core/theme/app_theme.dart';

class BodyInjectionPicker extends StatelessWidget {
  const BodyInjectionPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final InjectionSite selected;
  final ValueChanged<InjectionSite> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w * 1.45;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _BodySilhouettePainter(),
              ),
              for (final z in _zones) _zone(w, h, z),
            ],
          ),
        );
      },
    );
  }

  Widget _zone(double w, double h, _Zone z) {
    final isSel = selected == z.site;
    return Positioned(
      left: w * z.l,
      top: h * z.t,
      width: w * z.wd,
      height: h * z.ht,
      child: Material(
        color: isSel
            ? AppTheme.teal.withValues(alpha: 0.4)
            : AppTheme.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            onSelect(z.site);
          },
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSel
                    ? AppTheme.teal
                    : AppTheme.navy.withValues(alpha: 0.12),
                width: isSel ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: AppTheme.teal.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _Zone {
  const _Zone(this.site, this.l, this.t, this.wd, this.ht);

  final InjectionSite site;
  final double l;
  final double t;
  final double wd;
  final double ht;
}

const _zones = <_Zone>[
  _Zone(InjectionSite.upperLeftAbdomen, 0.26, 0.10, 0.2, 0.14),
  _Zone(InjectionSite.upperRightAbdomen, 0.54, 0.10, 0.2, 0.14),
  _Zone(InjectionSite.leftAbdomen, 0.2, 0.28, 0.25, 0.18),
  _Zone(InjectionSite.rightAbdomen, 0.55, 0.28, 0.25, 0.18),
  _Zone(InjectionSite.leftThigh, 0.25, 0.52, 0.2, 0.18),
  _Zone(InjectionSite.rightThigh, 0.55, 0.52, 0.2, 0.18),
  _Zone(InjectionSite.leftArm, 0.0, 0.18, 0.14, 0.2),
  _Zone(InjectionSite.rightArm, 0.86, 0.18, 0.14, 0.2),
];

class _BodySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    final o = Path();
    final cx = size.width * 0.5;
    o.addOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.08),
        width: size.width * 0.2,
        height: size.height * 0.1,
      ),
    );
    o.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height * 0.4),
          width: size.width * 0.42,
          height: size.height * 0.38,
        ),
        const Radius.circular(16),
      ),
    );
    o.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.6),
        width: size.width * 0.16,
        height: size.height * 0.12,
      ),
    );
    o.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.6),
        width: size.width * 0.16,
        height: size.height * 0.12,
      ),
    );
    canvas.drawPath(o, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
