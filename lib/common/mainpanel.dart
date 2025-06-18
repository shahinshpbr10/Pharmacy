import 'package:flutter/material.dart';
import 'package:zappq_pharmacy/Pages/call_section.dart';
import 'package:zappq_pharmacy/Pages/dashboard_section.dart';
import 'package:zappq_pharmacy/Pages/smartclinic.dart';
import '../Pages/chat_screen.dart';
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
        return DashBoardSection();
      case Section.Reminder:
        return Scaffold(body: Text("Reminder"));
      case Section.chat:
        return const ChatScreen();

      case Section.call:
        return const CallSection();
      case Section.saved:
        return SmartClinicControlScreen();
      default:
        return const Center(child: Text('Invalid section'));
    }
  }
}
