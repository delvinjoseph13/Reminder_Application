import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:assets_audio_player/assets_audio_player.dart';


class RemiderHomePage extends StatefulWidget {
  const RemiderHomePage({super.key});

  @override
  State<RemiderHomePage> createState() => _RemiderHomePageState();
}

class _RemiderHomePageState extends State<RemiderHomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
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
  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('notification payload: ${response.payload}');
        }
        // Play a sound when notification is selected
        AssetsAudioPlayer.newPlayer().open(
          Audio("assets/notification_sound.mp3"),
          autoStart: true,
        );
      },
    );
  }

  Future<void> scheduleNotification() async {
    try {
      if (selectedTime == null || selectedDay == null || selectedActivity == null) {
        return;
      }
      final int dayIndex = daysOfWeek.indexOf(selectedDay!);
      final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        nowTZ.year,
        nowTZ.month,
        nowTZ.day,
        selectedTime!.hour,
        selectedTime!.minute,
      ).add(Duration(days: (dayIndex - nowTZ.weekday + 7) % 7));

      debugPrint('Scheduled Date: $scheduledDate');

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'reminder_channel',
        'Reminder Notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Reminder',
        selectedActivity,
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notification Scheduled Successfully');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Reminder App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Day of the week"),
              value: selectedDay,
              items: daysOfWeek.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDay = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
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
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Activity"),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedDay != null &&
                    selectedTime != null &&
                    selectedActivity != null) {
                  scheduleNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder Set!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select all fields'),
                    ),
                  );
                }
              },
              child: Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}