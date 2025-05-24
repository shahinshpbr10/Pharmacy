import 'package:flutter/material.dart';
import 'package:zappq_pharmacy/common/sidebar.dart';

import '../common/mainpanel.dart';
import '../enum/enums.dart';


class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  Section _selectedSection = Section.Dashboard;

  void _onSectionTap(Section section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          SideBar(
            selectedSection: _selectedSection,
            onSectionTap: _onSectionTap,
          ),
          Expanded(
            child: MainPanel(selectedSection:_selectedSection ,),
          ),
        ],
      ),
    );
  }


}
