import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MedicalCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;
  final Color? borderColor;
  final EdgeInsets? padding;

  const MedicalCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = borderColor ?? AppTheme.primaryTeal;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: accentColor, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.secondaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const Divider(color: AppTheme.borderLight, height: 20),
              // Card Content
              child,
            ],
          ),
        ),
      ),
    );
  }
}
