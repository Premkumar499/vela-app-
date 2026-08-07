import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Professional POS-style bottom toolbar.
/// Hosts: Print, Save Bill, New Bill, Delete Item, Hold Bill, Cancel Bill, Settings.
class BottomToolbar extends StatelessWidget {
  final VoidCallback? onPrint;
  final VoidCallback? onSave;
  final VoidCallback? onNewBill;
  final VoidCallback? onDeleteItem;
  final VoidCallback? onHold;
  final VoidCallback? onCancel;
  final VoidCallback? onSettings;
  final bool isSaving;

  const BottomToolbar({
    super.key,
    this.onPrint,
    this.onSave,
    this.onNewBill,
    this.onDeleteItem,
    this.onHold,
    this.onCancel,
    this.onSettings,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.print,
            label: 'Print',
            color: Colors.white70,
            onPressed: onPrint,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.save_alt,
            label: 'Save Bill',
            color: Colors.greenAccent,
            onPressed: isSaving ? null : onSave,
            isLoading: isSaving,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.add_circle_outline,
            label: 'New Bill',
            color: Colors.lightBlueAccent,
            onPressed: onNewBill,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete Item',
            color: Colors.orangeAccent,
            onPressed: onDeleteItem,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.pause_circle_outline,
            label: 'Hold',
            color: Colors.amberAccent,
            onPressed: onHold,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel Bill',
            color: Colors.redAccent,
            onPressed: onCancel,
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            color: Colors.white54,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        color: isEnabled ? color : color.withValues(alpha: 0.3),
                        size: 22,
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isEnabled ? color : color.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white12,
    );
  }
}
