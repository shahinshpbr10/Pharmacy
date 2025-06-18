
import 'package:flutter/material.dart';

class CallSection extends StatelessWidget {
  const CallSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: Call list
        Container(
          width: 300,
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Row(
                  children: [
                    Text("Calls", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(backgroundImage: AssetImage('assets/zappq_icon.jpg')),
                      title: const Text("Shahinsh"),
                      subtitle: const Text("needed med urgent"),
                      trailing: Text("2:50", style: TextStyle(fontSize: 12)),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right panel: Placeholder or logo
        Expanded(
          child: Center(
            child: Image.asset('assets/ZAPPQ WORDMARK-01 2.png', height: 120),
          ),
        ),
      ],
    );
  }
}
