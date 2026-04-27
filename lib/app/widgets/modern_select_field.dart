import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ModernSelectItem<T> {
  const ModernSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

class ModernSelectField<T> extends StatelessWidget {
  const ModernSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onSelected,
    this.fieldLabel,
    this.sheetTitle,
    this.leading,
    this.allowClear = false,
    this.onClear,
  });

  final T? value;
  final List<ModernSelectItem<T>> items;
  final String hint;
  final void Function(T value) onSelected;
  final String? fieldLabel;
  final String? sheetTitle;
  final Widget? leading;
  final bool allowClear;
  final VoidCallback? onClear;

  ModernSelectItem<T>? get _active {
    if (value == null) {
      return null;
    }
    for (final it in items) {
      if (it.value == value) {
        return it;
      }
    }
    return null;
  }

  Future<void> _openSheet(BuildContext context) async {
    final t = await showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.72;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 32,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: h,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      sheetTitle ?? 'Selecionar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (allowClear && value != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ClearTile(
                        onTap: () {
                          onClear?.call();
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final sel = value == it.value;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx, it.value);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.teal.withValues(alpha: 0.1)
                                    : AppTheme.navy.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.teal.withValues(alpha: 0.45)
                                      : Colors.transparent,
                                  width: sel ? 1.5 : 0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppTheme.teal.withValues(alpha: 0.2)
                                          : AppTheme.navy
                                              .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      sel
                                          ? Icons.check_rounded
                                          : Icons.circle_outlined,
                                      size: 22,
                                      color: sel
                                          ? AppTheme.teal
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.label,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.navy,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (it.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            it.subtitle!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (t != null && context.mounted) {
      onSelected(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final act = _active;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: act != null
                  ? AppTheme.teal.withValues(alpha: 0.35)
                  : AppTheme.navy.withValues(alpha: 0.1),
              width: act != null ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fieldLabel != null) ...[
                      Text(
                        fieldLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      act == null ? hint : act.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: act == null ? FontWeight.w500 : FontWeight.w700,
                        color: act == null
                            ? AppTheme.textMuted
                            : AppTheme.navy,
                        height: 1.2,
                      ),
                    ),
                    if (act?.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        act!.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.unfold_more_rounded,
                color: AppTheme.teal,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearTile extends StatelessWidget {
  const _ClearTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.navy.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.close_rounded,
                size: 20,
                color: AppTheme.navy.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Text(
                'Limpar seleção',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
