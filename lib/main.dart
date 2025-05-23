import 'package:flutter/material.dart';
import 'package:zappq_pharmacy/auth.dart';
import 'package:zappq_pharmacy/sidenavbar.dart';

import 'chatlistpane.dart';
import 'messagepane.dart';

void main() => runApp(const ZappQPharmacy());

class ZappQPharmacy extends StatelessWidget {
  const ZappQPharmacy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZappQ Pharmacy',
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum NavItem { chat, calls, saved }

class ZappQPharmacyLanding extends StatefulWidget {
  const ZappQPharmacyLanding({super.key});

  @override
  State<ZappQPharmacyLanding> createState() => _ZappQPharmacyLandingState();
}

class _ZappQPharmacyLandingState extends State<ZappQPharmacyLanding> {
  NavItem _selected = NavItem.chat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideNavBar(
            selected: _selected,
            onTap: (item) => setState(() => _selected = item),
          ),

          Expanded(flex: 2, child: getLeftPanel(_selected)),
          VerticalDivider(width: 1),
          Expanded(flex: 5, child: getRightPanel(_selected)),
        ],
      ),
    );
  }

  Widget getLeftPanel(NavItem item) {
    if (item == NavItem.chat) {
      return ChatListPane(title: "Chats", items: [
        ChatItem(name: "Shahinsh", subtitle: "need med urget", time: "2:50"),
        ChatItem(name: "Doctor Ahmed", subtitle: "sent you a message", time: "2:49"),
      ]);
    }

    if (item == NavItem.calls) {
      return ChatListPane(title: "Calls", items: [
        ChatItem(name: "Shahinsh", subtitle: "Missed call", time: "2:51"),
        ChatItem(name: "Clinic A", subtitle: "Call duration: 2m", time: "2:45"),
      ]);
    }

    if (item == NavItem.saved) {
      return ChatListPane(title: "Saved", items: [
        ChatItem(name: "Prescription.pdf", subtitle: "Saved from Chat", time: "2:20"),
        ChatItem(name: "Reminder", subtitle: "Take Med @ 9PM", time: "2:18"),
      ]);
    }

    return const SizedBox();
  }


  Widget getRightPanel(NavItem item) {
    if (item == NavItem.chat) return const MessagePane();
    if (item == NavItem.calls) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image(
            image: const AssetImage('assets/ZAPPQ_word.png'),
            width: 180,
            errorBuilder: (context, error, stackTrace) =>
                Text("ZappQ logo not found"),
          ),
        ),
      );
    }
    return const Center(child: Text("📌 No saved messages."));
  }
}
