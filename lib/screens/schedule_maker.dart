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
    
    const notifications.InitializationSettings initializationSettings =
        notifications.InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notifications.NotificationResponse response) {
        // Handle notification tap
        _handleNotificationTap(response);
      },
    );

    // Request notification permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notifications.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _handleNotificationTap(notifications.NotificationResponse response) {
    // Handle what happens when user taps on notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification tapped: ${response.payload}')),
    );
  }

  Future<void> _scheduleStudySessionNotification(TimetableSlot slot, String day) async {
    // Generate unique ID based on day and subject
    int notificationId = '${day}_${slot.subject}'.hashCode;
    
    const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics =
        notifications.AndroidNotificationDetails(
      'study_sessions',
      'Study Session Reminders',
      channelDescription: 'Notifications for upcoming study sessions',
      importance: notifications.Importance.high,
      priority: notifications.Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const notifications.NotificationDetails platformChannelSpecifics =
        notifications.NotificationDetails(android: androidPlatformChannelSpecifics);

    // Calculate next occurrence of this day and time
    DateTime now = DateTime.now();
    int weekdayNumber = _getWeekdayNumber(day);
    int daysUntilTarget = (weekdayNumber - now.weekday) % 7;
    if (daysUntilTarget == 0 && _isTimeAfterNow(slot.startTime)) {
      daysUntilTarget = 7; // Schedule for next week if time has passed today
    }
    
    DateTime targetDate = now.add(Duration(days: daysUntilTarget));
    DateTime scheduledTime = _parseTimeForDate(slot.startTime, targetDate);
    
    // Schedule 15 minutes before the session
    DateTime notificationTime = scheduledTime.subtract(const Duration(minutes: 15));
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Study Session Reminder',
      '${slot.subject} starts in 15 minutes (${slot.startTime})',
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          notifications.UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'study_${slot.subject}_$day',
    );
  }

  Future<void> _scheduleTaskDeadlineNotification(TodoTask task) async {
    int notificationId = task.title.hashCode;
    
    const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics =
        notifications.AndroidNotificationDetails(
      'task_deadlines',
      'Task Deadline Reminders',
      channelDescription: 'Notifications for upcoming task deadlines',
      importance: notifications.Importance.high,
      priority: notifications.Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const notifications.NotificationDetails platformChannelSpecifics =
        notifications.NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      DateTime dueDate = DateTime.parse(task.dueDate);
      DateTime notificationTime = dueDate.subtract(const Duration(days: 1));
      
      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Task Deadline Reminder',
          'Task "${task.title}" is due tomorrow!',
          tz.TZDateTime.from(notificationTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              notifications.UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_${task.title}',
        );
      }
    } catch (e) {
      // Handle invalid date format
      print('Error scheduling notification for task: ${task.title}');
    }
  }

  Future<void> _cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
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

  bool _isTimeAfterNow(String timeString) {
    DateTime now = DateTime.now();
    DateTime time = _parseTimeForDate(timeString, now);
    return time.isBefore(now);
  }

  DateTime _parseTimeForDate(String timeString, DateTime date) {
    List<String> timeParts = timeString.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
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
            Text('📚 Study sessions: 15 min before start time'),
            SizedBox(height: 8),
            Text('📝 Task deadlines: 1 day before due date'),
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
            // Cancel notification before removing
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
                // Cancel notification when task is completed
                _cancelNotification(task.title.hashCode);
              } else {
                // Reschedule notification when task is uncompleted
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
                  'Due: ${task.dueDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.priority.color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              // Cancel notification before removing
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
    String startTime = '09:00';
    String endTime = '10:00';
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
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Start Time'),
                            initialValue: startTime,
                            onChanged: (value) => startTime = value,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'End Time'),
                            initialValue: endTime,
                            onChanged: (value) => endTime = value,
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
                            // Simple icon selection
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
                          child: Text('Enable reminder notifications (15 min before)'),
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
                        startTime: startTime,
                        endTime: endTime,
                        icon: selectedIcon,
                        color: selectedColor,
                        hasNotification: enableNotifications,
                      );
                      
                      setState(() {
                        weeklySchedule[selectedDay]!.add(newSlot);
                      });
                      
                      // Schedule notification if enabled
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
    String dueDate = DateTime.now().toString().split(' ')[0];
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
                      decoration:
                          const InputDecoration(labelText: 'Task Title'),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Description (optional)'),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Due Date (YYYY-MM-DD)'),
                      initialValue: dueDate,
                      onChanged: (value) => dueDate = value,
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
                          child: Text('Enable deadline notifications (1 day before)'),
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
                        dueDate: dueDate,
                        priority: selectedPriority,
                        hasNotification: enableNotifications,
                      );
                      
                      setState(() {
                        todoTasks.add(newTask);
                      });
                      
                      // Schedule notification if enabled
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
  final String dueDate;
  final TaskPriority priority;
  final bool hasNotification;
  bool isCompleted;

  TodoTask({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.hasNotification = false,
    this.isCompleted = false,
  });
}

enum TaskPriority {
  low('Low', Colors.teal),
  medium('Medium', Colors.orange),
  high('High', Colors.redAccent);

  const TaskPriority(this.name, this.color);
  final String name;
  final Color color;
}
