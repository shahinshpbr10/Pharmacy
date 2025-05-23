import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class SideNavBar extends StatelessWidget {
  final NavItem selected;
  final Function(NavItem) onTap;

  const SideNavBar({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: const Color(0xFFDDDDDD),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/zappq_icon.jpg', width: 40)),
              ),
              SizedBox(height: 50,),
              navIcon(Icons.chat, NavItem.chat),
              navIcon(Icons.call, NavItem.calls),
              navIcon(Icons.bookmark, NavItem.saved),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
          ),
        ],
      ),
    );
  }

  Widget navIcon(IconData icon, NavItem item) {
    final isActive = selected == item;
    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.black),
      ),
    );
  }
}
