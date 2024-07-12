import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

List<int> vibrationPatternList = [0, 1000, 500, 2000];
Int64List vibrationPattern = Int64List.fromList(vibrationPatternList);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

await AwesomeNotifications().initialize(
  null,
  [
    NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic notifications',
      channelDescription: 'Notification channel for basic tests',
      defaultColor: Color(0xFF9B6BC3),
      importance: NotificationImportance.Default,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern, 
      soundSource: 'resource://raw/notification_sound',
    ),
  ],
);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const ReminderHomePage(),
    );
  }
}

class ReminderHomePage extends StatefulWidget {
  const ReminderHomePage({super.key});

  @override
  State<ReminderHomePage> createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> {
  final List<String> activities = [
    "Wake up",
    "Go to gym",
    "Breakfast",
    "Meetings",
    "Lunch",
    "Quick nap",
    "Go to library",
    "Dinner",
    "Go to sleep"
  ];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  // Function to schedule a notification
  Future<void> scheduleNotification() async {
    if (selectedDate == null || selectedTime == null || selectedActivity == null) {
      return;
    }

    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final scheduledDate = tz.TZDateTime.from(
      scheduledDateTime,
      tz.getLocation('Asia/Kolkata'), 
    );

await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 1,
    channelKey: 'basic_channel', 
    title: 'Reminder',
    body: selectedActivity!,
    notificationLayout: NotificationLayout.BigText,
  ),
  schedule: NotificationInterval(
    interval: 60, 
    timeZone: 'Asia/Kolkata', 
    repeats: false, 
  ),
);
  print('Reminder scheduled for: ${scheduledDateTime.hour}:${scheduledDateTime.minute} ');

}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminder App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                // Show date picker dialog
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: selectedDate != null
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : "Choose date",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                // Show time picker dialog
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: selectedTime != null
                        ? selectedTime!.format(context)
                        : "Choose time",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Activity"),
              value: selectedActivity,
              items: activities.map((String activity) {
                return DropdownMenuItem<String>(
                  value: activity,
                  child: Text(activity),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedActivity = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Validate and schedule the notification
                if (selectedDate != null &&
                    selectedTime != null &&
                    selectedActivity!= null) {
                  scheduleNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder Set!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select all fields'),
                    ),
                  );
                }
              },
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}