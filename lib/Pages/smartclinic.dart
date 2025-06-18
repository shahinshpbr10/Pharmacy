import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zappq_pharmacy/Pages/smartclinicdetailssetpage.dart';

class SmartClinicControlScreen extends StatefulWidget {
  @override
  State<SmartClinicControlScreen> createState() => _SmartClinicControlScreenState();
}

class _SmartClinicControlScreenState extends State<SmartClinicControlScreen> {
  Stream<QuerySnapshot> bookingStream = FirebaseFirestore.instance
      .collection('smartclinic_booking')
      .orderBy('createdAt', descending: true)
      .snapshots();

  DocumentSnapshot? selectedBookingDoc; // Hold the selected doc for right pane

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar chat list
          Container(
            width: 320,
            color: Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Text(
                        'Smart Clinic',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Icon(Icons.filter_list),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.all(0),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: bookingStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No Bookings Found'));
                      }

                      final bookings = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final name = booking['patientName'] ?? 'Unknown';
                          final phone = booking['phoneNumber'] ?? '';
                          final timeSlot = booking['selectedTimeSlot'] ?? '';
                          // final type = booking['selectedBookingType'] ?? '';
                          final date = booking['selectedDate']?.toDate();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            ),
                            title: Text(name.isEmpty ? 'No Name' : name),
                            // subtitle: Text('$type\n$timeSlot'),
                            trailing: Text(
                              date != null
                                  ? "${date.day}/${date.month} ${date.hour}:${date.minute}"
                                  : '',
                              style: TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              setState(() {
                                selectedBookingDoc = booking;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main detail panel
          Expanded(
            child: selectedBookingDoc == null
                ? Center(child: Text("Select a booking to see details"))
                : BookingDetailsScreen(bookingDoc: selectedBookingDoc!),
          ),
        ],
      ),
    );
  }
}
