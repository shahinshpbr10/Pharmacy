
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashBoardSection extends StatefulWidget {
  const DashBoardSection({super.key});

  @override
  State<DashBoardSection> createState() => _DashBoardSectionState();
}

class _DashBoardSectionState extends State<DashBoardSection> {
  late List<Meeting> _meetings;
  late MeetingDataSource _dataSource;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _meetings = [];
    _dataSource = MeetingDataSource(_meetings);

    FirebaseFirestore.instance.collection('calendar_events').snapshots().listen((snapshot) {
      final List<Meeting> loadedMeetings = snapshot.docs.map((doc) {
        final data = doc.data();
        return Meeting(
          data['title'] ?? 'Untitled',
          DateTime.parse(data['from']),
          DateTime.parse(data['to']),
          _hexToColor(data['color'] ?? "#2196F3"),
          data['isAllDay'] ?? false,
          doc.id,
        );
      }).toList();

      setState(() {
        _meetings = loadedMeetings;
        _dataSource = MeetingDataSource(_meetings);
      });
    });
  }

  void showAddOrEditDialog(Meeting? meeting) {
    final controller = TextEditingController(text: meeting?.eventName ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(meeting == null ? 'New Event' : 'Edit Event'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Event Title'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 10);
                final end = start.add(const Duration(hours: 1));
                final event = {
                  'title': controller.text,
                  'from': start.toIso8601String(),
                  'to': end.toIso8601String(),
                  'color': '#9C27B0',
                  'isAllDay': false,
                };

                if (meeting == null) {
                  await FirebaseFirestore.instance.collection('calendar_events').add(event);
                } else {
                  await FirebaseFirestore.instance
                      .collection('calendar_events')
                      .doc(meeting.docId)
                      .update(event);
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('calendar_events').doc(meeting.docId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 300,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("LAB OVERVIEW", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildInfoCard(title: "New Bookings", value: "5", showBadge: true),
              _buildInfoCard(title: "Total Bookings", value: "35"),
              const SizedBox(height: 12),
              const Text("Pharma Overview", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildInfoCard(title: "New Orders", value: "5", showBadge: true),
              _buildInfoCard(title: "Total Orders", value: "35"),
              const SizedBox(height: 12),
              _buildInfoCard(title: "Total Revenue", value: "₹42,000"),
              _buildInfoCard(title: "Total Enquiries", value: "12"),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF8F8F8),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Schedules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: SfCalendar(
                    view: CalendarView.month,
                    dataSource: _dataSource,
                    allowDragAndDrop: true,
                    allowAppointmentResize: true,
                    showDatePickerButton: true,
                    showNavigationArrow: true,
                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                      showAgenda: true,
                    ),
                    onTap: (details) {
                      if (details.targetElement == CalendarElement.calendarCell) {
                        setState(() => _selectedDate = details.date ?? DateTime.now());
                        showAddOrEditDialog(null);
                      } else if (details.targetElement == CalendarElement.appointment &&
                          details.appointments?.first is Meeting) {
                        showAddOrEditDialog(details.appointments!.first as Meeting);
                      }
                    },
                    onLongPress: (details) {
                      if (details.appointments?.first is Meeting) {
                        _confirmDelete(details.appointments!.first as Meeting);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    Color? bgColor,
    Color? textColor,
    bool showBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFEAF8EC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (showBadge)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text("5", style: TextStyle(color: Colors.white, fontSize: 10)),
                  )
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor ?? Colors.black),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }
}

class Meeting {
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay, [this.docId = ""]);

  final String eventName;
  final DateTime from;
  final DateTime to;
  final Color background;
  final bool isAllDay;
  final String docId;
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => _getMeetingData(index).from;
  @override
  DateTime getEndTime(int index) => _getMeetingData(index).to;
  @override
  String getSubject(int index) => _getMeetingData(index).eventName;
  @override
  Color getColor(int index) => _getMeetingData(index).background;
  @override
  bool isAllDay(int index) => _getMeetingData(index).isAllDay;

  Meeting _getMeetingData(int index) => appointments![index] as Meeting;
}
