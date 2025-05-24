import 'package:flutter/material.dart';
import '../enum/enums.dart';


class MainPanel extends StatefulWidget {
  final Section selectedSection;

  const MainPanel({
    super.key,
    required this.selectedSection,
  });

  @override
  State<MainPanel> createState() => _MainPanelState();
}

class _MainPanelState extends State<MainPanel> {
  @override
  Widget build(BuildContext context) {
    switch (widget.selectedSection) {
      case Section.Dashboard:
        return Scaffold(body: Text("Dashboard"));
      case Section.Reminder:
        return Scaffold(body: Text("Reminder"));
      case Section.chat:
        return const Placeholder();

      case Section.call:
        return const Scaffold(body: Text("Call"),);
      case Section.saved:
        return const Scaffold(body: Text("Saved"));
      default:
        return const Center(child: Text('Invalid section'));
    }
  }
}
