import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FreezeSlotGrid extends StatelessWidget {
  final String dateKey;

  const FreezeSlotGrid({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('id_counters')
        .doc('lab_booking_counter');

    final List<String> timeSlots = [
      "8:00 AM - 9:00 AM",
      "9:00 AM - 10:00 AM",
      "10:00 AM - 11:00 AM",
      "11:00 AM - 12:00 PM",
      "12:00 PM - 1:00 PM",
      "1:00 PM - 2:00 PM",
      "2:00 PM - 3:00 PM",
      "3:00 PM - 4:00 PM",
      "4:00 PM - 5:00 PM",
      "5:00 PM - 6:00 PM",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Freeze Slot for $dateKey',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back icon color
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final dateSlots = Map<String, dynamic>.from(data[dateKey] ?? {});

          return Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              itemCount: timeSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2, // Smaller slot size
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final slot = timeSlots[index];
                final isFrozen = dateSlots[slot] == 1;

                return GestureDetector(
                  onTap: () async {
                    final newValue = isFrozen ? 0 : 1;

                    await docRef.set({
                      dateKey: {slot: newValue}
                    }, SetOptions(merge: true));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Slot "$slot" set to ${newValue == 1 ? 'Frozen' : 'Unfrozen'}',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFrozen ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      slot,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isFrozen ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
