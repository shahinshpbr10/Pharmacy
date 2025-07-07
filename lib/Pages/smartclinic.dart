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

  DocumentSnapshot? selectedBookingDoc;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
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
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by patient name...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.all(0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.toLowerCase().trim();
                      });
                    },
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

                      final allBookings = snapshot.data!.docs;

                      // Apply search filter
                      final filteredBookings = _searchText.isEmpty
                          ? allBookings
                          : allBookings.where((doc) {
                        final name = (doc['patientName'] ?? '').toString().toLowerCase();
                        return name.contains(_searchText);
                      }).toList();

                      if (filteredBookings.isEmpty) {
                        return Center(child: Text('No matching bookings'));
                      }

                      return ListView.builder(
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final name = booking['patientName'] ?? 'Unknown';
                          final phone = booking['phoneNumber'] ?? '';
                          final timeSlot = booking['selectedTimeSlot'] ?? '';
                          final date = booking['selectedDate']?.toDate();
                          final status = booking['status']??"";

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            ),
                            title: Text(name.isEmpty ? 'No Name' : name),
                            subtitle: Text(status),
                            trailing: Text(
                              date != null
                                  ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}"
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

          // Details view
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
