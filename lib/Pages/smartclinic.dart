import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  DateTime? _selectedFilterDate;
  String? _selectedStatus;

  final List<String> _statusOptions = ['Pending', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _setIsOpenedFalseIfMissing();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setIsOpenedFalseIfMissing() async {
    final snapshot = await FirebaseFirestore.instance.collection('smartclinic_booking').get();
    for (var doc in snapshot.docs) {
      if (!doc.data().containsKey('isOpened')) {
        await doc.reference.update({'isOpened': false});
      }
    }
    if (!mounted) return;
    print("Missing 'isOpened' fields set to false.");
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String? tempStatus = _selectedStatus;
        return AlertDialog(
          title: Text('Select Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _statusOptions.map((status) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: tempStatus,
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
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
                    children: [
                      const Text(
                        'Smart Clinic',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (value) async {
                          if (value == 'date') {
                            DateTime now = DateTime.now();
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedFilterDate ?? now,
                              firstDate: now.subtract(Duration(days: 365)),
                              lastDate: now.add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              if (!mounted) return;
                              setState(() {
                                _selectedFilterDate = picked;
                              });
                            }
                          } else if (value == 'status') {
                            _showStatusDialog(context);
                          } else if (value == 'clear') {
                            if (!mounted) return;
                            setState(() {
                              _selectedFilterDate = null;
                              _selectedStatus = null;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'date', child: Text('Filter by Date')),
                          PopupMenuItem(value: 'status', child: Text('Filter by Status')),
                          PopupMenuItem(value: 'clear', child: Text('Clear Filters')),
                        ],
                      ),
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
                      if (!mounted) return;
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

                      final filteredBookings = allBookings.where((doc) {
                        final name = (doc['patientName'] ?? '').toString().toLowerCase();
                        final bookingDate = doc['selectedDate']?.toDate();
                        final status = (doc['status'] ?? '').toString().toLowerCase();

                        final matchesName = _searchText.isEmpty || name.contains(_searchText);
                        final matchesDate = _selectedFilterDate == null ||
                            (bookingDate != null &&
                                bookingDate.year == _selectedFilterDate!.year &&
                                bookingDate.month == _selectedFilterDate!.month &&
                                bookingDate.day == _selectedFilterDate!.day);
                        final matchesStatus = _selectedStatus == null ||
                            status == _selectedStatus!.toLowerCase();

                        return matchesName && matchesDate && matchesStatus;
                      }).toList();

                      if (filteredBookings.isEmpty) {
                        return Center(child: Text('No matching bookings'));
                      }

                      return ListView.builder(
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final name = booking['patientName'] ?? 'Unknown';
                          final date = booking['selectedDate']?.toDate();
                          final status = booking['status'] ?? "";
                          final isOpened = booking['isOpened'] == true;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                              ),
                            ),
                            title: Text(name.isEmpty ? 'No Name' : name),
                            subtitle: Text(status),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isOpened) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                SizedBox(width: 10,),
                                Text(
                                  date != null
                                      ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                                      : '',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            onTap: () async {
                              if (!mounted) return;
                              setState(() {
                                selectedBookingDoc = booking;
                              });
                              if (!isOpened) {
                                await booking.reference.update({'isOpened': true});
                              }
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
