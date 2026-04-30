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
        final h = (w * 1.78).clamp(320.0, 680.0);
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/corpo.png',
                  width: w,
                  height: h,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: w,
                      height: h,
                      color: AppTheme.navy.withValues(alpha: 0.05),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textMuted,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              for (final z in _zones) _zone(w, h, z, context),
            ],
          ),
        );
      },
    );
  }

  Widget _zone(double w, double h, _Zone z, BuildContext context) {
    final isSel = selected == z.site;
    return Positioned(
      left: (w * z.x) - z.size / 2,
      top: (h * z.y) - z.size / 2,
      width: z.size,
      height: z.size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            onSelect(z.site);
          },
          customBorder: const CircleBorder(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSel
                  ? AppTheme.teal.withValues(alpha: 0.8)
                  : AppTheme.navy.withValues(alpha: 0.28),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: AppTheme.teal.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Tooltip(
              message: z.site.labelKey,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Zone {
  const _Zone(this.site, this.x, this.y, this.size);

  final InjectionSite site;
  final double x;
  final double y;
  final double size;
}

const _zones = <_Zone>[
  _Zone(InjectionSite.upperLeftAbdomen, 0.46, 0.41, 28),
  _Zone(InjectionSite.upperRightAbdomen, 0.54, 0.41, 28),
  _Zone(InjectionSite.leftAbdomen, 0.45, 0.46, 30),
  _Zone(InjectionSite.rightAbdomen, 0.55, 0.46, 30),
  _Zone(InjectionSite.leftThigh, 0.46, 0.56, 30),
  _Zone(InjectionSite.rightThigh, 0.54, 0.56, 30),
  _Zone(InjectionSite.leftArm, 0.36, 0.24, 28),
  _Zone(InjectionSite.rightArm, 0.64, 0.24, 28),
];
