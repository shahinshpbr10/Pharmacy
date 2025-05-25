
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/Events.dart';

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
    _meetings = _getDataSource();
    _dataSource = MeetingDataSource(_meetings);
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (meeting != null) {
                    final index = _meetings.indexWhere((m) =>
                    m.eventName == meeting.eventName &&
                        m.from == meeting.from &&
                        m.to == meeting.to);
                    if (index != -1) {
                      _meetings[index] = Meeting(
                        controller.text,
                        meeting.from,
                        meeting.to,
                        meeting.background,
                        meeting.isAllDay,
                      );
                    }
                  } else {
                    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 10);
                    final end = start.add(const Duration(hours: 1));
                    _meetings.add(Meeting(controller.text, start, end, Colors.purple, false));
                  }
                  _dataSource = MeetingDataSource(_meetings);
                });
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
            onPressed: () {
              setState(() {
                _meetings.remove(meeting);
                _dataSource = MeetingDataSource(_meetings);
              });
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
        // Left Panel
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

        // Right Panel: Calendar
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
                    onTap: (CalendarTapDetails details) {
                      if (details.targetElement == CalendarElement.calendarCell) {
                        setState(() => _selectedDate = details.date ?? DateTime.now());
                        showAddOrEditDialog(null);
                      } else if (details.targetElement == CalendarElement.appointment &&
                          details.appointments?.first is Meeting) {
                        final appt = details.appointments!.first as Meeting;
                        showAddOrEditDialog(appt);
                      }
                    },
                    onLongPress: (CalendarLongPressDetails details) {
                      if (details.appointments?.first is Meeting) {
                        _confirmDelete(details.appointments!.first as Meeting);
                      }
                    },
                    onDragEnd: (AppointmentDragEndDetails details) {
                      final Object? dragged = details.appointment;

                      if (dragged is Meeting && details.droppingTime != null) {
                        setState(() {
                          final index = _meetings.indexWhere((m) =>
                          m.eventName == dragged.eventName &&
                              m.from == dragged.from &&
                              m.to == dragged.to);
                          if (index != -1) {
                            final duration = dragged.to.difference(dragged.from);
                            final newStart = details.droppingTime!;
                            final newEnd = newStart.add(duration);

                            _meetings[index] = Meeting(
                              dragged.eventName,
                              newStart,
                              newEnd,
                              dragged.background,
                              dragged.isAllDay,
                            );

                            _dataSource = MeetingDataSource(_meetings);
                          }
                        });
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
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
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
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "5",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Meeting> _getDataSource() {
    final List<Meeting> meetings = <Meeting>[];
    final DateTime today = DateTime.now();
    final DateTime startTime = DateTime(today.year, today.month, today.day, 9);
    final DateTime endTime = startTime.add(const Duration(hours: 2));
    meetings.add(Meeting('Conference', startTime, endTime, const Color(0xFF0F8644), false));
    meetings.add(Meeting('Team Review', today.add(const Duration(days: 2, hours: 11)),
        today.add(const Duration(days: 2, hours: 12)), Colors.deepOrange, false));
    meetings.add(Meeting('Doctor Visit', today.add(const Duration(days: 3, hours: 10)),
        today.add(const Duration(days: 3, hours: 11)), Colors.blue, false));
    return meetings;
  }
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

  Meeting _getMeetingData(int index) {
    final dynamic meeting = appointments![index];
    return meeting is Meeting ? meeting : Meeting('', DateTime.now(), DateTime.now(), Colors.grey, false);
  }
}


