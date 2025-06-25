import 'dart:convert';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';
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



  Future<void> _pickAndUploadFile({required bool isBill}) async {
    setState(() => isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
          'pdf', 'doc', 'docx', 'txt', 'rtf',
          'xls', 'xlsx', 'csv',
          'ppt', 'pptx',
          'zip', 'rar', '7z',
          'mp4', 'avi', 'mov', 'wmv', 'mp3', 'wav',
          'html', 'css', 'js', 'json', 'xml'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final uid = widget.bookingDoc['uid'];
        final patientName = widget.bookingDoc['patientName'] ?? 'unknown';
        final testName = widget.bookingDoc['serviceName'] ?? 'test';
        final docRef = FirebaseFirestore.instance
            .collection('app_users')
            .doc(uid)
            .collection('health_documents')
            .doc('SmartClinic');

        final docSnapshot = await docRef.get();
        final data = docSnapshot.data();

        List<dynamic> fileNames = data?['fileNames'] ?? [];
        List<dynamic> fileUrls = data?['fileUrls'] ?? [];
        List<dynamic> uploadDates = data?['uploadDates'] ?? [];
        List<dynamic> fileSizes = data?['fileSizes'] ?? [];

        for (final file in result.files) {
          final fileName = file.name;
          final fileBytes = file.bytes;
          final fileExtension = fileName.split('.').last.toLowerCase();

          if (fileBytes == null) continue;

          if (isBill && fileExtension != 'pdf') {
            _showSnackBar('Only PDF files are allowed for bills.', Colors.red);
            continue;
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final finalName = "$testName-$patientName-$timestamp.$fileExtension";
          final filePath = isBill
              ? 'bills_upload/$uid/bills/$finalName'
              : 'users/$uid/health_documents/SmartClinic/$finalName';

          final storageRef = FirebaseStorage.instance.ref().child(filePath);

          // Generate a simple random token string
          final randomToken = base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(256)));

          final metadata = SettableMetadata(
            contentType: _getContentType(fileExtension),
            contentDisposition: 'inline',
          );


          final uploadTask = await storageRef.putData(fileBytes, metadata);
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
            fileNames.add(finalName);
            fileUrls.add(downloadUrl);
            uploadDates.add(Timestamp.now());
            fileSizes.add(file.size);
          }

          _showSnackBar('File "$fileName" uploaded successfully', Colors.green);
        }

        if (!isBill) {
          print('-------');
          print(uid);
          print('-------');

          final totalSize = fileSizes.fold<double>(0, (sum, size) => sum + size);
          await docRef.set({
            'fileNames': fileNames,
            'fileUrls': fileUrls,
            'uploadDates': uploadDates,
            'fileSizes': fileSizes,
            'totalFiles': fileNames.length,
            'spaceUsed': '${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB',
            'name': 'SmartClinic',
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e, stack) {
      print("UPLOAD ERROR: $e");
      print("STACKTRACE: $stack");
      _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
    }

    setState(() => isUploading = false);
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

    final doc = await FirebaseFirestore.instance.collection('lab_tests').doc(selectedTestId).get();
    if (doc.exists) {
      final data = doc.data()!;
      addonTests.add(data);
      addonPrice += (data['PATIENT_RATE'] as num?)?.toInt() ?? 0;
      setState(() => selectedTestId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeTest(int index) async {
    final test = addonTests[index];
    addonPrice -= (test['PATIENT_RATE'] as num?)?.toInt() ?? 0;
    addonTests.removeAt(index);
    setState(() {});
  }

  Future<void> _saveAddonTests() async {
    setState(() => isUploading = true);
    try {
      await FirebaseFirestore.instance.collection('smartclinic_booking')
          .doc(widget.bookingDoc.id)
          .update({
        'addon_tests': addonTests,
        'addon_price': addonPrice
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
                    _buildInfoRow(Icons.person_outline, "Name", data['patientName'] ?? 'N/A'),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, "Phone", data['phoneNumber'] ?? 'N/A'),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, "Test name ", data['serviceName'] ?? 'N/A'),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.medical_services, "Type", data['bookingType'] ?? 'N/A'),
                    if (data['location'] != null) ...[
                      SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on,
                        "Location",
                        data['address'] != null
                            ? "Lat: ${data['location'].latitude}, Lng: ${data['location'].longitude}"
                            : 'Not Available',
                      ),

                    ],
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
                            onPressed: () => _openMap(data['address'] ?? ''),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading ? null : () => _pickAndUploadFile(isBill: false),
                            icon: Icon(Icons.description),
                            label: Flexible(
                              child: Text(
                                "Test Report",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading ? null : () => _pickAndUploadFile(isBill: true),
                            icon: Icon(Icons.receipt),
                            label: Flexible(
                              child: Text(
                                "Test Bill",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
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
                          .snapshots(), // Listen for document changes
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Show loading indicator while waiting
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

                          return SearchableDropdown.single(
                            hint: Text("Select a test to add"),
                            value: selectedTestId,
                            items: docs.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc.id,  // Setting the test id as value
                                child: Text(
                                  doc['TEST_NAME'] ?? 'Unknown Test',  // Displaying test name
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedTestId = value); // Update selectedTestId when changed
                            },
                            isExpanded: true,
                            iconEnabledColor: Colors.blue,  // Customize icon color if needed
                          );
                        },
                      ),
                    ),

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
            if (addonTests.isNotEmpty) ...[
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
                          SizedBox(width: 8),
                          Text(
                            "Selected Tests",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: addonTests.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final test = addonTests[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(Icons.science, color: Colors.blue[600], size: 20),
                          ),
                          title: Text(
                            test['TEST_NAME'] ?? 'Unknown Test',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
                            onPressed: () => _removeTest(index),
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : _saveAddonTests,
                  child: isUploading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Saving..."),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text("Save Add-On Tests"),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

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