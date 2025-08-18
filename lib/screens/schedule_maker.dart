import 'package:flutter/material.dart';

class ScheduleMakerScreen extends StatefulWidget {
  const ScheduleMakerScreen({super.key});

  @override
  State<ScheduleMakerScreen> createState() => _ScheduleMakerScreenState();
}

class _ScheduleMakerScreenState extends State<ScheduleMakerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      subtitle: Text('${slot.startTime} - ${slot.endTime}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          setState(() {
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
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
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
                      setState(() {
                        weeklySchedule[selectedDay]!.add(
                          TimetableSlot(
                            subject: subject,
                            startTime: startTime,
                            endTime: endTime,
                            icon: selectedIcon,
                            color: selectedColor,
                          ),
                        );
                      });
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
    Priority selectedPriority = Priority.medium;

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
                    DropdownButtonFormField<Priority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: Priority.values.map((priority) {
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
                      setState(() {
                        todoTasks.add(
                          TodoTask(
                            title: title,
                            description: description,
                            dueDate: dueDate,
                            priority: selectedPriority,
                          ),
                        );
                      });
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

  TimetableSlot({
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.icon,
    required this.color,
  });
}

class TodoTask {
  final String title;
  final String description;
  final String dueDate;
  final Priority priority;
  bool isCompleted;

  TodoTask({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
  });
}

enum Priority {
  low('Low', Colors.teal),
  medium('Medium', Colors.orange),
  high('High', Colors.redAccent);

  const Priority(this.name, this.color);
  final String name;
  final Color color;
}
