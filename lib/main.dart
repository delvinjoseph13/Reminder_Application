import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Initialize the notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  await _initializeNotifications();
  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  final InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  // Check for plugin version compatibility with onSelectNotification (if applicable)
  try {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  } on Exception catch (error) {
    debugPrint('Error initializing notifications: $error');
  } catch (error) {
    debugPrint('Unexpected error: $error'); // Catch other potential errors
  }

  await _createNotificationChannel();
  await _createReminderNotificationChannel(); // Create separate channel for taps
}

Future<void> _createNotificationChannel() async {
  // Define the main notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'eminder_channel', // Channel ID
    'Reminder Notifications', // Channel Name
    description: 'This channel is used for reminder notifications.',
    importance: Importance.high, // Set importance to high
    sound: RawResourceAndroidNotificationSound('notification_sound'),
  );

  // Create the main notification channel
  await flutterLocalNotificationsPlugin
     .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
     ?.createNotificationChannel(channel);
}

// Channel ID for reminder tap notifications
const String reminderNotificationChannelId = 'eminder_channel_tap';

Future<void> _createReminderNotificationChannel() async {
  // Define the channel for reminder tap notifications
  await flutterLocalNotificationsPlugin
     .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
     ?.createNotificationChannel(createReminderNotificationChannel());
}

// Function to create the reminder tap notification channel
AndroidNotificationChannel createReminderNotificationChannel() =>
    AndroidNotificationChannel(
      reminderNotificationChannelId, // Channel ID for reminder taps
      'Reminder Tap Notifications', // Channel name for reminder taps
      description:
          'This channel is used for handling reminder notification taps.',
      importance: Importance.low,
    );

// MyApp widget definition
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

// ReminderHomePage widget definition
class ReminderHomePage extends StatefulWidget {
  const ReminderHomePage({super.key});

  @override
  State<ReminderHomePage> createState() => _ReminderHomePageState();
}

// _ReminderHomePageState definition
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
  final ringtonePlayer = FlutterRingtonePlayer(); // Instance for ringtone player

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
    tz.getLocation('Asia/Kolkata'), // Use 'Asia/Kolkata' for IST
  );

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'eminder_channel', // Main channel ID
    'Reminder Notifications', // Main channel name
    channelDescription: 'This channel is used for reminder notifications.',
    importance: Importance.high, // Set importance to high
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
    playSound: true,
    enableVibration: true,
  );

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID (unique for each notification)
      'Reminder', // Notification title
      selectedActivity!, // Notification body
      scheduledDate, // Scheduled date and time
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Reminder Notification', // Payload for identification
    );

    print('Reminder scheduled for: ${scheduledDateTime.hour}:${scheduledDateTime.minute}');

    // Play notification sound
    await ringtonePlayer.playNotification();
  } catch (e) {
    print('Error scheduling notification: $e');
  }
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
                if (pickedDate!= null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: selectedDate!= null
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
                if (pickedTime!= null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: selectedTime!= null
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
                if (selectedDate!= null &&
                    selectedTime!= null &&
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