import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SlotManagement extends StatefulWidget {
  @override
  _SlotManagementState createState() => _SlotManagementState();
}

class _SlotManagementState extends State<SlotManagement> {
  late bool isThirtyMinutes;
  late List<String> allSlots;
  late List<String> selectedSlots;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    isThirtyMinutes = false; // Initially set to 1-hour slots
    allSlots = _generateTimeSlots(isThirtyMinutes);
    selectedSlots = [];
    _loadExistingSlots(); // Load existing slots from Firestore
  }

  // Load existing slots from Firestore with enhanced error handling
  Future<void> _loadExistingSlots() async {
    try {
      print("Loading existing slots from Firestore...");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('lab_timeslots')
          .get();

      print("Document exists: ${doc.exists}");
      print("Document data: ${doc.data()}");

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> times = data['times'] ?? [];

        print("Loaded times: $times");

        setState(() {
          selectedSlots = times.cast<String>();
          isLoading = false;
        });
      } else {
        print("Document doesn't exist, creating with empty slots");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading timeslots: $e");
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading timeslots: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }

  // Convert 24-hour to 12-hour format with AM/PM
  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12; // Handle 12 AM and 12 PM cases
    return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
  }

  // Generate slots based on 1-hour or 30-minute intervals in 12-hour format
  List<String> _generateTimeSlots(bool thirtyMinutes) {
    List<String> slots = [];
    DateTime startTime = DateTime(0, 1, 1, 8, 0); // Starting at 8:00 AM
    DateTime endTime = DateTime(0, 1, 1, 18, 0); // Ending at 6:00 PM

    while (startTime.isBefore(endTime)) {
      DateTime slotEnd = startTime.add(Duration(minutes: thirtyMinutes ? 30 : 60));
      String slot = "${_formatTime(startTime)} - ${_formatTime(slotEnd)}";
      slots.add(slot);
      startTime = slotEnd;
    }

    return slots;
  }

  // Enhanced save method with better error handling and logging
  Future<void> _saveSelectedSlots() async {
    if (isSaving) return; // Prevent multiple saves

    setState(() {
      isSaving = true;
    });

    try {
      print("Saving selected slots: $selectedSlots");

      // Using merge: true to ensure we don't overwrite other fields
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('lab_timeslots')
          .set({
        'times': selectedSlots,
      }, SetOptions(merge: true));

      print("Successfully saved to Firestore");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timeslots updated successfully! (${selectedSlots.length} slots)'),
              backgroundColor: Colors.green,
            )
        );
      }

      // Verify the save by reading back
      await _verifyFirebaseSave();

    } catch (e) {
      print("Error updating timeslots: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating timeslots: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  // Verify that data was actually saved to Firebase
  Future<void> _verifyFirebaseSave() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('lab_timeslots')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> savedTimes = data['times'] ?? [];
        print("Verification - Data in Firebase: $savedTimes");
        print("Verification - Local data: $selectedSlots");

        if (savedTimes.length != selectedSlots.length) {
          print("WARNING: Mismatch between local and Firebase data!");
        }
      } else {
        print("WARNING: Document not found during verification!");
      }
    } catch (e) {
      print("Error during verification: $e");
    }
  }

  // Toggle slot selection (without immediate save)
  void _toggleSlotSelection(String slot) {
    setState(() {
      if (selectedSlots.contains(slot)) {
        selectedSlots.remove(slot);
      } else {
        selectedSlots.add(slot);
      }
    });
    print("Selected slots count: ${selectedSlots.length}");
  }

  // Handle slot duration change
  void _onSlotDurationChanged(bool? value) {
    if (value == null) return;

    setState(() {
      isThirtyMinutes = value;
      allSlots = _generateTimeSlots(isThirtyMinutes);
      // Filter existing selected slots to keep only valid ones for new duration
      selectedSlots = selectedSlots.where((slot) => allSlots.contains(slot)).toList();
    });
  }

  // Select all slots
  void _selectAllSlots() {
    setState(() {
      selectedSlots = List.from(allSlots);
    });
  }

  // Clear all selections
  void _clearAllSlots() {
    setState(() {
      selectedSlots.clear();
    });
  }

  // Test Firebase connection
  Future<void> _testFirebaseConnection() async {
    try {
      print("Testing Firebase connection...");
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test'
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firebase connection successful!'),
              backgroundColor: Colors.green,
            )
        );
      }

      // Clean up test document
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .delete();

    } catch (e) {
      print("Firebase connection test failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firebase connection failed: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Manage Timeslots'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Debug button to test Firebase connection

          if (isSaving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveSelectedSlots, // Always allow saving, even empty lists
              tooltip: 'Save Timeslots',
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 8),

            // Slot Duration Radio Buttons
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slot Duration:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isThirtyMinutes,
                          onChanged: _onSlotDurationChanged,
                        ),
                        Text('1 Hour Slots'),
                        SizedBox(width: 20),
                        Radio<bool>(
                          value: true,
                          groupValue: isThirtyMinutes,
                          onChanged: _onSlotDurationChanged,
                        ),
                        Text('30 Minutes Slots'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectAllSlots,
                  icon: Icon(Icons.select_all),
                  label: Text('Select All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearAllSlots,
                  icon: Icon(Icons.clear),
                  label: Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '${selectedSlots.length} of ${allSlots.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Timeslot Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: allSlots.length,
                itemBuilder: (context, index) {
                  String slot = allSlots[index];
                  bool isSelected = selectedSlots.contains(slot);

                  return GestureDetector(
                    onTap: () => _toggleSlotSelection(slot),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}