import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../enum/enums.dart';
import '../Widgets/buildiconbutton.dart'; // Contains SidebarIconButton

class SideBar extends StatelessWidget {
  final Section selectedSection;
  final ValueChanged<Section> onSectionTap;

  const SideBar({
    super.key,
    required this.selectedSection,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [ const SizedBox(height: 20),
ClipRRect(
  borderRadius: BorderRadius.all(Radius.circular(8)),

  child: Image(image: AssetImage('assets/zappq_icon.jpg'),width: 45,
  height:  45,),
),
          const SizedBox(height: 60),
          SidebarIconButton(
            icon: Icons.dashboard,
            label: 'Dashboard',
            section: Section.Dashboard,
            selectedSection: selectedSection,
            onTap: onSectionTap,
          ),
          SidebarIconButton(
            icon: Icons.chat,
            label: 'Chat',
            section: Section.chat,
            selectedSection: selectedSection,
            onTap: onSectionTap,
          ),
          SidebarIconButton(
            icon: Icons.call,
            label: 'Call',
            section: Section.call,
            selectedSection: selectedSection,
            onTap: onSectionTap,
          ),
          SidebarIconButton(
            icon: Iconsax.hospital,
            label: 'S Clinic',
            section: Section.saved,
            selectedSection: selectedSection,
            onTap: onSectionTap,
          ),
          // SidebarIconButton(
          //   icon: Icons.lock_clock,
          //   label: 'Reminder',
          //   section: Section.Reminder,
          //   selectedSection: selectedSection,
          //   onTap: onSectionTap,
          // ),
        ],
      ),
    );
  }
}
