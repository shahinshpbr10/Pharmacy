import 'package:flutter/material.dart';
import '../enum/enums.dart'; // Enum Section { chat, call, saved }

class SidebarIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Section section;
  final Section selectedSection;
  final void Function(Section) onTap;

  const SidebarIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.section,
    required this.selectedSection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedSection == section;

    return GestureDetector(
      onTap: () => onTap(section),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.green : Colors.black54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.green : Colors.black54,
            ),
          ),
          const SizedBox(height: 16), // spacing between items
        ],
      ),
    );
  }
}
