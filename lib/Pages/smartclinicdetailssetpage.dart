import 'dart:convert';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class BookingDetailsScreen extends StatefulWidget {
  final DocumentSnapshot bookingDoc;
  const BookingDetailsScreen({super.key, required this.bookingDoc});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  String? selectedTestId;
  List<Map<String, dynamic>> addonTests = [];
  int addonPrice = 0;
  bool isUploading = false;
  List<PlatformFile> pickedReports = [];
  List<PlatformFile> pickedBills = [];

  Future<void> _pickFiles({required bool isBill}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx',
      ],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (isBill) {
          pickedBills.addAll(result.files);
        } else {
          pickedReports.addAll(result.files);
        }
      });
    }
  }

  Future<void> _uploadFiles({required bool isBill}) async {
    final selectedFiles = isBill ? pickedBills : pickedReports;
    if (selectedFiles.isEmpty) {
      _showSnackBar('Please pick files first.', Colors.orange);
      return;
    }

    setState(() => isUploading = true);
    final uid = widget.bookingDoc['uid'];
    final patientName = widget.bookingDoc['patientName'] ?? 'unknown';
    final testName = widget.bookingDoc['serviceName'] ?? 'test';

    try {
      for (final file in selectedFiles) {
        final fileName = file.name;
        final fileBytes = file.bytes;
        final fileExtension = fileName.split('.').last.toLowerCase();

        if (fileBytes == null) continue;

        final fileSizeInMB = file.size / (1024 * 1024);
        if (fileSizeInMB > 1.5) {
          _showSnackBar('File "$fileName" is too large (max 1.5 MB).', Colors.red);
          continue;
        }

        if (isBill && fileExtension != 'pdf') {
          _showSnackBar('Bills must be PDF.', Colors.red);
          continue;
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final finalName = "$testName-$patientName-$timestamp.$fileExtension";
        final filePath = isBill
            ? 'bills_upload/$uid/bills/$finalName'
            : 'users/$uid/health_documents/SmartClinic/$finalName';

        final ref = FirebaseStorage.instance.ref().child(filePath);
        final metadata = SettableMetadata(contentType: _getContentType(fileExtension));
        final uploadTask = await ref.putData(fileBytes, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        if (isBill) {
          await FirebaseFirestore.instance.collection('smartclinicbills').add({
            'userId': uid,
            'patientName': patientName,
            'testName': testName,
            'fileUrl': downloadUrl,
            'fileName': finalName,
            'createdAt': Timestamp.now(),
          });
        } else {
          final docRef = FirebaseFirestore.instance
              .collection('app_users')
              .doc(uid)
              .collection('health_documents')
              .doc('SmartClinic');

          final doc = await docRef.get();
          List<dynamic> names = doc['fileNames'] ?? [];
          List<dynamic> urls = doc['fileUrls'] ?? [];
          List<dynamic> dates = doc['uploadDates'] ?? [];
          List<dynamic> sizes = doc['fileSizes'] ?? [];

          names.add(finalName);
          urls.add(downloadUrl);
          dates.add(Timestamp.now());
          sizes.add(file.size);

          await docRef.set({
            'fileNames': names,
            'fileUrls': urls,
            'uploadDates': dates,
            'fileSizes': sizes,
            'totalFiles': names.length,
          }, SetOptions(merge: true));
        }

        _showSnackBar('Uploaded: $fileName', Colors.green);
      }

      // Clear after upload
      setState(() {
        if (isBill) {
          pickedBills.clear();
        } else {
          pickedReports.clear();
        }
      });
    } catch (e) {
      _showSnackBar('Upload failed: $e', Colors.red);
    }

    setState(() => isUploading = false);
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildUploadedReports() {
    final uid = widget.bookingDoc['uid'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('app_users')
          .doc(uid)
          .collection('health_documents')
          .doc('SmartClinic')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text("No reports uploaded yet.");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final names = List<String>.from(data['fileNames'] ?? []);
        final urls = List<String>.from(data['fileUrls'] ?? []);

        return _buildFilePreview(names, urls, (index) async {
          final confirm = await _showConfirmDialog("Delete this report?");
          if (!confirm) return;

          final fileName = names[index];
          final fileUrl = urls[index];

          // Remove from Firebase Storage
          try {
            final ref = await FirebaseStorage.instance.refFromURL(fileUrl);
            await ref.delete();
          } catch (_) {}

          // Remove from Firestore
          names.removeAt(index);
          urls.removeAt(index);

          await FirebaseFirestore.instance
              .collection('app_users')
              .doc(uid)
              .collection('health_documents')
              .doc('SmartClinic')
              .update({
            'fileNames': names,
            'fileUrls': urls,
            'uploadDates': FieldValue.arrayRemove([data['uploadDates'][index]]),
            'fileSizes': FieldValue.arrayRemove([data['fileSizes'][index]]),
            'totalFiles': names.length,
          });

          setState(() {});
        });
      },
    );
  }

  Widget _buildUploadedBills() {
    final uid = widget.bookingDoc['uid'];

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('smartclinicbills')
          .where('userId', isEqualTo: uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text("No bills uploaded yet.");
        }

        final docs = snapshot.data!.docs;

        final names = docs.map((doc) => doc['fileName'] as String).toList();
        final urls = docs.map((doc) => doc['fileUrl'] as String).toList();

        return _buildFilePreview(names, urls, (index) async {
          final confirm = await _showConfirmDialog("Delete this bill?");
          if (!confirm) return;

          try {
            final ref = await FirebaseStorage.instance.refFromURL(urls[index]);
            await ref.delete();
          } catch (_) {}

          await docs[index].reference.delete();
          setState(() {});
        });
      },
    );
  }

  Widget _buildFilePreview(List<String> names, List<String> urls, void Function(int index) onDelete) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(names.length, (i) {
        final name = names[i];
        final url = urls[i];
        final isImage = name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                    image: isImage
                        ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                        : null,
                  ),
                  child: !isImage
                      ? Center(child: Icon(Icons.insert_drive_file, size: 36, color: Colors.deepPurple))
                      : null,
                ),
                // Delete button
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => onDelete(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              width: 80,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[800]),
              ),
            ),
          ],
        );
      }),
    );
  }



  void _makePhoneCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMap(GeoPoint? geoPoint) async {
    if (geoPoint == null) return;

    final lat = geoPoint.latitude;
    final lng = geoPoint.longitude;

    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Google Maps'), backgroundColor: Colors.red),
      );
    }
  }

  String formatSelectedDate(dynamic timestamp) {
    if (timestamp == null) return 'No Date';
    final date = (timestamp is Timestamp) ? timestamp.toDate() : timestamp;
    return DateFormat('dd MMMM yyyy').format(date as DateTime);
  }


  String _getContentType(String extension) {
    final map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'csv': 'text/csv',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',
    };
    return map[extension] ?? 'application/octet-stream';
  }


  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addTestToBooking() async {
    if (selectedTestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a test first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('lab_tests')
          .doc(selectedTestId)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected test not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = doc.data()!;
      addonTests.add(data);
      addonPrice += (data['PATIENT_RATE'] as num?)?.toInt() ?? 0;

      // Convert all tests to serializable map
      final serializableTests = addonTests.map((e) => Map<String, dynamic>.from(e)).toList();

      await FirebaseFirestore.instance
          .collection('smartclinic_booking')
          .doc(currentBookingId)
          .update({
        'addon_tests': serializableTests,
        'addon_price': addonPrice,
      });

      setState(() {
        selectedTestId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error while adding test: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add test'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _removeTest(int index) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('smartclinic_booking')
          .doc(currentBookingId);

      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('addon_tests')) return;

      // Get the current list of tests
      final List<Map<String, dynamic>> tests =
      List<Map<String, dynamic>>.from(data['addon_tests']);

      if (index < 0 || index >= tests.length) return;

      // Remove the test at the given index
      final removedTest = tests.removeAt(index);

      // Get the price of the removed test
      final int removedPrice = (removedTest['PATIENT_RATE'] as num?)?.toInt() ?? 0;

      // Get current total addon price
      final int currentPrice = (data['addon_price'] as num?)?.toInt() ?? 0;

      // Subtract the test price from total, but don't allow it to go below 0
      final int newPrice = (currentPrice - removedPrice).clamp(0, double.infinity).toInt();

      // Update Firestore
      await docRef.update({
        'addon_tests': tests,
        'addon_price': newPrice,
      });

      // StreamBuilder will auto-refresh the UI
    } catch (e) {
      print("Error removing test: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove test. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _saveAddonTests() async {
    setState(() => isUploading = true);
    try {
      await FirebaseFirestore.instance
          .collection('smartclinic_booking')
          .doc(widget.bookingDoc.id)
          .update({
        'addon_tests': addonTests,
        'addon_price': addonPrice,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add-on tests saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => isUploading = false);
  }


  // Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
  //   try {
  //     // Fetching the address directly using the geocoding package
  //     List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
  //
  //     // Just returning the first available address as plain text (without filtering)
  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks.first;
  //       return place.toString();  // Return the Placemark object in its default string format
  //     } else {
  //       return "Address not available";
  //     }
  //   } catch (e) {
  //     print("Error getting address: $e");
  //     return "Error decoding address";
  //   }
  // }
  String? currentBookingId;


  void _initializeAddonTests() {
    final data = widget.bookingDoc.data() as Map<String, dynamic>;

    // Clear existing data first
    addonTests.clear();
    addonPrice = 0;

    // Load existing addon tests if they exist
    if (data['addon_tests'] != null) {
      addonTests = List<Map<String, dynamic>>.from(data['addon_tests']);
    }

    // Load existing addon price if it exists
    if (data['addon_price'] != null) {
      addonPrice = (data['addon_price'] as num?)?.toInt() ?? 0;
    }

    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    currentBookingId = widget.bookingDoc.id;
    _initializeAddonTests();
  }

  @override
  void didUpdateWidget(BookingDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the booking document has changed, reinitialize the addon tests
    if (oldWidget.bookingDoc.id != widget.bookingDoc.id) {
      currentBookingId = widget.bookingDoc.id;
      _initializeAddonTests();
    }
  }



  @override
  Widget build(BuildContext context) {
    final data = widget.bookingDoc.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Booking Details", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xff9DD645),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Information Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Patient Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20, thickness: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.person_outline, "Name", data['patientName'] ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.phone, "Phone", data['phoneNumber'] ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.location_on, "Address", data['address'] ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.science, "Test Name", data['serviceName'] ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.medical_services, "Type", data['bookingType'] ?? 'N/A'),
                            ],
                          ),
                        ),

                        SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.access_time, "Time Slot", data['selectedTimeSlot'] ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.attach_money, "Delivery Charge", data['deliveryCharge']?.toString() ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.monetization_on, "Service Charge", data['servicePrice']?.toString() ?? 'N/A'),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.calendar_today, "Slot Date", formatSelectedDate((data['selectedDate'] as Timestamp).toDate())),
                              SizedBox(height: 12),
                              _buildInfoRow(Icons.payment, "Payment Type", data['selectedPaymentMethod']?.toString() ?? 'N/A'),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(data['phoneNumber'] ?? ''),
                            icon: Icon(Icons.phone),
                            label: Flexible(
                              child: Text(
                                "Call Patient",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openMap(data['location'] ?? ''),
                            icon: Icon(Icons.map),
                            label: Flexible(
                              child: Text(
                                "View Location",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // File Upload Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.orange[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Upload Documents",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // 🧾 Picked Test Reports Preview
                    if (pickedReports.isNotEmpty) ...[
                      Text(
                        "Picked Test Reports",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: pickedReports.map((file) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade200,
                                      image: file.extension!.contains('jp') || file.extension == 'png'
                                          ? DecorationImage(
                                        image: MemoryImage(file.bytes!),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: !(file.extension!.contains('jp') || file.extension == 'png')
                                        ? Center(
                                      child: Icon(Icons.insert_drive_file,
                                          size: 36, color: Colors.deepPurple),
                                    )
                                        : null,
                                  ),
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => pickedReports.remove(file)),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black87,
                                        ),
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  file.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                                ),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],

                 // 📃 Picked Test Bills Preview
                    if (pickedBills.isNotEmpty) ...[
                      Text(
                        "Picked Test Bills",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: pickedBills.map((file) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade200,
                                      image: file.extension!.contains('jp') || file.extension == 'png'
                                          ? DecorationImage(
                                        image: MemoryImage(file.bytes!),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: !(file.extension!.contains('jp') || file.extension == 'png')
                                        ? Center(
                                      child: Icon(Icons.insert_drive_file,
                                          size: 36, color: Colors.deepPurple),
                                    )
                                        : null,
                                  ),
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => pickedBills.remove(file)),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black87,
                                        ),
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  file.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                                ),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ],


                    SizedBox(height: 16),

                    // Buttons for Pick + Upload
                    Row(
                      children: [
                        // === REPORT BUTTON + PREVIEW ===
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isUploading ? null : () async {
                                  await _pickFiles(isBill: false);
                                  await _uploadFiles(isBill: false);
                                },
                                icon: Icon(Icons.upload_file),
                                label: Text("Upload Report", overflow: TextOverflow.ellipsis),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildUploadedReports(), // ⬅️ Show previously uploaded reports
                            ],
                          ),
                        ),

                        SizedBox(width: 12),

                        // === BILL BUTTON + PREVIEW ===
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isUploading ? null : () async {
                                  await _pickFiles(isBill: true);
                                  await _uploadFiles(isBill: true);
                                },
                                icon: Icon(Icons.receipt),
                                label: Text("Upload Bill", overflow: TextOverflow.ellipsis),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildUploadedBills(), // ⬅️ Show previously uploaded bills
                            ],
                          ),
                        ),
                      ],
                    ),



                  ],
                ),
              ),
            ),


            SizedBox(height: 16),
            // Status Update Dropdown
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.teal[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Update Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('smartclinic_booking')
                          .doc(widget.bookingDoc.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text('Document not found');
                        }

                        final data = snapshot.data!.data() as Map<String, dynamic>;

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          value: ['pending', 'approved', 'in-progress', 'sample Collected', 'processing', 'completed']
                              .contains(data['status']) ? data['status'] : 'Pending', // Check if status is valid
                          items: ['pending', 'approved', 'in-progress', 'sample Collected', 'processing', 'completed']
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                              .toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              // Prepare the update data
                              Map<String, dynamic> updateData = {'status': value};

                              // If the status is 'completed', add or update the 'completedAt' field
                              if (value == 'completed') {
                                updateData['completedAt'] = FieldValue.serverTimestamp(); // Generate timestamp for completion
                              }

                              // Update Firestore document with the new status (and completedAt if applicable)
                              await FirebaseFirestore.instance
                                  .collection('smartclinic_booking')
                                  .doc(widget.bookingDoc.id)
                                  .update(updateData);

                              // Show confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Status updated to $value'), backgroundColor: Colors.teal),
                              );
                            }
                          },
                        )
                        ;
                      },
                    )


                  ],
                ),
              ),
            ),

            // Add-on Tests Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.purple[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Add-On Tests",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Test Selection Dropdown
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('lab_tests').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          // Convert Firestore docs to List<Map<String, dynamic>> format like your doctors
                          final labTests = docs.map((doc) {
                            return {
                              'id': doc.id,
                              'TEST_NAME': doc['TEST_NAME'] ?? 'Unknown Test',
                              'PATIENT_RATE': doc['PATIENT_RATE'] ?? 0,
                            };
                          }).toList();

                          return Expanded(
                            child: DropdownSearch<String>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search lab tests...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              items: labTests.isNotEmpty
                                  ? labTests.map((test) => test['id'] as String).toList()
                                  : [],
                              dropdownBuilder: (context, selectedId) {
                                if (selectedId == null || labTests.isEmpty) {
                                  return const Text(
                                    'Select Lab Test',
                                    style: TextStyle(fontSize: 16),
                                  );
                                }

                                final test = labTests.firstWhere(
                                        (t) => t['id'] == selectedId,
                                    orElse: () => {'TEST_NAME': 'Unknown', 'PATIENT_RATE': 0}
                                );

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${test['TEST_NAME']}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '₹${test['PATIENT_RATE']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              itemAsString: (id) {
                                if (id == null || labTests.isEmpty) return 'Select Lab Test';

                                final test = labTests.firstWhere(
                                        (t) => t['id'] == id,
                                    orElse: () => {'TEST_NAME': 'Unknown', 'PATIENT_RATE': 0}
                                );

                                return '${test['TEST_NAME']} (₹${test['PATIENT_RATE']})';
                              },
                              selectedItem: selectedTestId,
                              onChanged: (value) async {
                                if (value == null) return;

                                setState(() {
                                  selectedTestId = value;
                                  // Add any other state resets you need here
                                });
                                // Add any additional logic you need when test is selected
                              },
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Lab Test",
                                  hintText: "Select Lab Test",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    ,

                    SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addTestToBooking,
                        icon: Icon(Icons.add),
                        label: Text("Add Selected Test"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Selected Tests List
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('smartclinic_booking')
                  .doc(currentBookingId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox(); // or a message like "No tests found"
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final addonTestsRaw = data['addon_tests'] ?? [];
                final List<Map<String, dynamic>> addonTests = List<Map<String, dynamic>>.from(addonTestsRaw);

                final int addonPrice = addonTests.fold<int>(
                  0,
                      (sum, item) => sum + (item['PATIENT_RATE'] as num?)!.toInt() ?? 0,
                );

                if (addonTests.isEmpty) return const SizedBox();

                return Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.list_alt, color: Colors.indigo[600], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "Selected Tests",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Total: ₹$addonPrice",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: addonTests.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final test = addonTests[index];
                              return ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.science, color: Colors.blue[600], size: 20),
                                ),
                                title: Text(
                                  test['TEST_NAME'] ?? 'Unknown Test',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                subtitle: Text(
                                  "₹${test['PATIENT_RATE'] ?? 0}",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[600], size: 20),
                                  onPressed: () => _removeTest(index), // ← Firestore + UI update
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Save Button

                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton(
                    //     onPressed: isUploading ? null : _saveAddonTests,
                    //     child: isUploading
                    //         ? Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: const [
                    //         SizedBox(
                    //           width: 20,
                    //           height: 20,
                    //           child: CircularProgressIndicator(
                    //             strokeWidth: 2,
                    //             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    //           ),
                    //         ),
                    //         SizedBox(width: 12),
                    //         Text("Saving..."),
                    //       ],
                    //     )
                    //         : Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: const [
                    //         Icon(Icons.save),
                    //         SizedBox(width: 8),
                    //         Text("Save Add-On Tests"),
                    //       ],
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.green[600],
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 16),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              },
            ),


            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}