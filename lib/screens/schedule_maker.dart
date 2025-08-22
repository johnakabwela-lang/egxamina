import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ScheduleMakerScreen extends StatefulWidget {
  const ScheduleMakerScreen({super.key});

  @override
  State<ScheduleMakerScreen> createState() => _ScheduleMakerScreenState();
}

class _ScheduleMakerScreenState extends State<ScheduleMakerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      notifications.FlutterLocalNotificationsPlugin();

  // Study Timetable Data
  Map<String, List<TimetableSlot>> weeklySchedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  // To-Do List Data
  List<TodoTask> todoTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const notifications.AndroidInitializationSettings initializationSettingsAndroid =
        notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const notifications.DarwinInitializationSettings initializationSettingsIOS =
        notifications.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const notifications.InitializationSettings initializationSettings =
        notifications.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notifications.NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // Request notification permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notifications.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request notification permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notifications.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _handleNotificationTap(notifications.NotificationResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification tapped: ${response.payload}')),
    );
  }

  Future<void> _scheduleStudySessionNotification(TimetableSlot slot, String day) async {
    int notificationId = '${day}_${slot.subject}'.hashCode.abs();
    
    const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics =
        notifications.AndroidNotificationDetails(
      'study_sessions',
      'Study Session Reminders',
      channelDescription: 'Notifications for study sessions',
      importance: notifications.Importance.max,
      priority: notifications.Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notifications.DarwinNotificationDetails iOSPlatformChannelSpecifics =
        notifications.DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notifications.NotificationDetails platformChannelSpecifics =
        notifications.NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

    // Calculate next occurrence of this day and time
    DateTime now = DateTime.now();
    int weekdayNumber = _getWeekdayNumber(day);
    int daysUntilTarget = (weekdayNumber - now.weekday) % 7;
    
    DateTime targetDate = now.add(Duration(days: daysUntilTarget == 0 ? 7 : daysUntilTarget));
    DateTime scheduledTime = _parseTimeForDate(slot.startTime, targetDate);
    
    // If the time has already passed today, schedule for next week
    if (daysUntilTarget == 0 && scheduledTime.isBefore(now)) {
      targetDate = now.add(const Duration(days: 7));
      scheduledTime = _parseTimeForDate(slot.startTime, targetDate);
    }
    
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Study Session: ${slot.subject}',
        'Your ${slot.subject} session is starting now!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            notifications.UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'study_${slot.subject}_$day',
        matchDateTimeComponents: notifications.DateTimeComponents.dayOfWeekAndTime,
      );
      
      print('Scheduled notification for ${slot.subject} on $day at ${slot.startTime}');
    } catch (e) {
      print('Error scheduling study session notification: $e');
    }
  }

  Future<void> _scheduleTaskDeadlineNotification(TodoTask task) async {
    int notificationId = task.title.hashCode.abs();
    
    const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics =
        notifications.AndroidNotificationDetails(
      'task_deadlines',
      'Task Deadline Reminders',
      channelDescription: 'Notifications for task deadlines',
      importance: notifications.Importance.max,
      priority: notifications.Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notifications.DarwinNotificationDetails iOSPlatformChannelSpecifics =
        notifications.DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notifications.NotificationDetails platformChannelSpecifics =
        notifications.NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

    try {
      DateTime dueDateTime = DateTime.parse(task.dueDateTimeString);
      
      // Only schedule if the due time is in the future
      if (dueDateTime.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Task Due: ${task.title}',
          'Your task "${task.title}" is due now!',
          tz.TZDateTime.from(dueDateTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              notifications.UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_${task.title}',
        );
        
        print('Scheduled notification for task "${task.title}" at $dueDateTime');
      }
    } catch (e) {
      print('Error scheduling task notification: $e');
    }
  }

  Future<void> _cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId.abs());
  }

  int _getWeekdayNumber(String day) {
    switch (day) {
      case 'Monday': return 1;
      case 'Tuesday': return 2;
      case 'Wednesday': return 3;
      case 'Thursday': return 4;
      case 'Friday': return 5;
      case 'Saturday': return 6;
      case 'Sunday': return 7;
      default: return 1;
    }
  }

  DateTime _parseTimeForDate(String timeString, DateTime date) {
    List<String> timeParts = timeString.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, {TimeOfDay? initialTime}) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, {DateTime? initialDate}) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<DateTime?> _selectDateTime(BuildContext context, {DateTime? initialDateTime}) async {
    final DateTime? date = await _selectDate(context, initialDate: initialDateTime);
    if (date == null) return null;
    
    final TimeOfDay? time = await _selectTime(
      context, 
      initialTime: initialDateTime != null 
        ? TimeOfDay.fromDateTime(initialDateTime) 
        : TimeOfDay.now()
    );
    if (time == null) return null;
    
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('Schedule Maker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_view_week),
              text: 'Study Timetable',
            ),
            Tab(
              icon: Icon(Icons.checklist),
              text: 'To-Do List',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimetableTab(),
          _buildTodoTab(),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📚 Study sessions: At exact start time'),
            SizedBox(height: 8),
            Text('📝 Task deadlines: At exact due date and time'),
            SizedBox(height: 8),
            Text('🔔 Notifications are automatically scheduled when you add items'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Study Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTimetableSlotDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: weeklySchedule.entries.map((entry) {
              return _buildDayCard(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String day, List<TimetableSlot> slots) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          day,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${slots.length} study sessions'),
        children: [
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No study sessions scheduled',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...slots.map((slot) => _buildTimetableSlotTile(slot, day)),
        ],
      ),
    );
  }

  Widget _buildTimetableSlotTile(TimetableSlot slot, String day) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: slot.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          slot.icon,
          color: slot.color,
        ),
      ),
      title: Text(slot.subject),
      subtitle: Row(
        children: [
          Text('${slot.startTime} - ${slot.endTime}'),
          const SizedBox(width: 8),
          if (slot.hasNotification)
            const Icon(
              Icons.notifications_active,
              size: 16,
              color: Colors.green,
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          setState(() {
            int notificationId = '${day}_${slot.subject}'.hashCode;
            _cancelNotification(notificationId);
            weeklySchedule[day]!.remove(slot);
          });
        },
      ),
    );
  }

  Widget _buildTodoTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks & Assignments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTodoDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: todoTasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todoTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTodoTile(todoTasks[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTodoTile(TodoTask task, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            setState(() {
              task.isCompleted = value ?? false;
              if (task.isCompleted) {
                _cancelNotification(task.title.hashCode);
              } else {
                _scheduleTaskDeadlineNotification(task);
              }
            });
          },
          activeColor: const Color(0xFF2196F3),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) Text(task.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: task.priority.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${task.formattedDueDateTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.priority.color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: task.priority.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.priority.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: task.priority.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (task.hasNotification) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.notifications_active,
                    size: 16,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _cancelNotification(task.title.hashCode);
              todoTasks.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _showAddTimetableSlotDialog() {
    String selectedDay = 'Monday';
    String subject = '';
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    IconData selectedIcon = Icons.book;
    Color selectedColor = Colors.blue;
    bool enableNotifications = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Study Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: weeklySchedule.keys.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDay = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Subject'),
                      onChanged: (value) => subject = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await _selectTime(context, initialTime: startTime);
                              if (picked != null) {
                                setDialogState(() {
                                  startTime = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Time'),
                              child: Text(_formatTimeOfDay(startTime)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await _selectTime(context, initialTime: endTime);
                              if (picked != null) {
                                setDialogState(() {
                                  endTime = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Time'),
                              child: Text(_formatTimeOfDay(endTime)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Subject Icon: '),
                        IconButton(
                          onPressed: () {
                            final icons = [
                              Icons.book,
                              Icons.science,
                              Icons.calculate,
                              Icons.history,
                              Icons.language,
                              Icons.palette,
                            ];
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Select Icon'),
                                content: Wrap(
                                  children: icons
                                      .map((icon) => IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                selectedIcon = icon;
                                              });
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(icon),
                                          ))
                                      .toList(),
                                ),
                              ),
                            );
                          },
                          icon: Icon(selectedIcon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Color: '),
                        ...([
                          Colors.blue,
                          Colors.teal,
                          Colors.orange,
                          Colors.indigo,
                          Colors.green,
                          Colors.amber
                        ]).map((color) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: enableNotifications,
                          onChanged: (value) {
                            setDialogState(() {
                              enableNotifications = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('Enable reminder notifications (at start time)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (subject.isNotEmpty) {
                      final newSlot = TimetableSlot(
                        subject: subject,
                        startTime: _formatTimeOfDay(startTime),
                        endTime: _formatTimeOfDay(endTime),
                        icon: selectedIcon,
                        color: selectedColor,
                        hasNotification: enableNotifications,
                      );
                      
                      setState(() {
                        weeklySchedule[selectedDay]!.add(newSlot);
                      });
                      
                      if (enableNotifications) {
                        _scheduleStudySessionNotification(newSlot, selectedDay);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Study session added with notification reminder!'),
                          ),
                        );
                      }
                      
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTodoDialog() {
    String title = '';
    String description = '';
    DateTime dueDateTime = DateTime.now().add(const Duration(days: 1));
    TaskPriority selectedPriority = TaskPriority.medium;
    bool enableNotifications = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Task Title'),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await _selectDateTime(context, initialDateTime: dueDateTime);
                        if (picked != null) {
                          setDialogState(() {
                            dueDateTime = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date & Time'),
                        child: Text(
                          '${dueDateTime.day}/${dueDateTime.month}/${dueDateTime.year} at ${_formatTimeOfDay(TimeOfDay.fromDateTime(dueDateTime))}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: priority.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(priority.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: enableNotifications,
                          onChanged: (value) {
                            setDialogState(() {
                              enableNotifications = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('Enable deadline notifications (at due time)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      final newTask = TodoTask(
                        title: title,
                        description: description,
                        dueDateTime: dueDateTime,
                        priority: selectedPriority,
                        hasNotification: enableNotifications,
                      );
                      
                      setState(() {
                        todoTasks.add(newTask);
                      });
                      
                      if (enableNotifications) {
                        _scheduleTaskDeadlineNotification(newTask);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task added with deadline reminder!'),
                          ),
                        );
                      }
                      
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TimetableSlot {
  final String subject;
  final String startTime;
  final String endTime;
  final IconData icon;
  final Color color;
  final bool hasNotification;

  TimetableSlot({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.icon,
    required this.color,
    this.hasNotification = false,
  });
}

class TodoTask {
  final String title;
  final String description;
  final DateTime dueDateTime;
  final TaskPriority priority;
  final bool hasNotification;
  bool isCompleted;

  TodoTask({
    required this.title,
    required this.description,
    required this.dueDateTime,
    required this.priority,
    this.hasNotification = false,
    this.isCompleted = false,
  });

  // Helper getter for the date-time string format needed for notifications
  String get dueDateTimeString => dueDateTime.toIso8601String();

  // Helper getter for formatted display
  String get formattedDueDateTime {
    return '${dueDateTime.day}/${dueDateTime.month}/${dueDateTime.year} ${dueDateTime.hour.toString().padLeft(2, '0')}:${dueDateTime.minute.toString().padLeft(2, '0')}';
  }
}

enum TaskPriority {
  low('Low', Colors.teal),
  medium('Medium', Colors.orange),
  high('High', Colors.redAccent);

  const TaskPriority(this.name, this.color);
  final String name;
  final Color color;
}
