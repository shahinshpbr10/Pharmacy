import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../Pages/logout_helper.dart';
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
          // SidebarIconButton(
          //   icon: Icons.call,
          //   label: 'Call',
          //   section: Section.call,
          //   selectedSection: selectedSection,
          //   onTap: onSectionTap,
          // ),
          SidebarIconButton(
            icon: Iconsax.hospital,
            label: 'S Clinic',
            section: Section.saved,
            selectedSection: selectedSection,
            onTap: onSectionTap,
          ),
          SidebarIconButton(
            icon: Iconsax.ticket,
            label: 'Slots',
            section: Section.Slots,
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
          Align(
            alignment: Alignment.bottomCenter,
            child: IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                          }
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  ));
            }, icon: Icon(Icons.logout)),
          )
        ],
      ),
    );
  }
}
