import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Settings group tile matching the web app's settings row pattern.
class SettingsGroupTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String? badge;
  final bool isToggle;
  final bool toggleValue;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleChanged;
  final bool showDivider;

  const SettingsGroupTile({
    super.key,
    required this.icon,
    this.iconBgColor = const Color(0x1A1A506C),
    this.iconColor = AppTheme.primary,
    required this.label,
    this.badge,
    this.isToggle = false,
    this.toggleValue = false,
    this.onTap,
    this.onToggleChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isToggle ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (badge != null) SizedBox(width: 8),
                if (isToggle)
                  Switch(
                    value: toggleValue,
                    onChanged: onToggleChanged,
                    activeThumbColor: AppTheme.primary,
                  )
                else
                  Icon(Icons.chevron_right,
                      color: AppTheme.textTertiary, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 68, color: AppTheme.actionButton),
      ],
    );
  }
}


