import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; //initialize Firestore
  String _selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout), //logout icon
            onPressed: () async {
              await _auth.signOut(); //sign out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()), //display LoginScreen
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    labelText: 'Enter task name',
                  ),
                ),
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Enter time (e.g., 9 am - 10 am)',
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedDay,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDay = newValue!;
                    });
                  },
                  items: <String>[
                    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTask, //add task
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('tasks').snapshots(), //get tasks from Firestore
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!.docs; //get tasks from snapshot
                Map<String, List<Map<String, dynamic>>> groupedTasks = {};

                for (var task in tasks) {
                  String day = task['day'] ?? 'Unknown';
                  if (!groupedTasks.containsKey(day)) {
                    groupedTasks[day] = [];
                  }
                  groupedTasks[day]!.add({ //add task to groupedTasks
                    'id': task.id,
                    'name': task['name'] ?? 'Unnamed Task',
                    'completed': task['completed'] ?? false,
                    'day': day,
                    'time': task['time'] ?? 'Unknown Time',
                  });
                }

                return ListView.builder(
                  itemCount: groupedTasks.keys.length,
                  itemBuilder: (context, index) {
                    String day = groupedTasks.keys.elementAt(index);
                    List<Map<String, dynamic>> dayTasks = groupedTasks[day]!; //get tasks for the day

                    return ExpansionTile(
                      title: Text(day),
                      children: dayTasks.map((task) {
                        return ListTile(
                          title: Text('${task['time']}: ${task['name']}'),
                          leading: Checkbox(
                            value: task['completed'],
                            onChanged: (bool? value) {
                              _toggleTaskCompletion(task['id'], value!);
                            },
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteTask(task['id']);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty && _timeController.text.isNotEmpty) {
      _firestore.collection('tasks').add({ //add task to Firestore
        'name': _taskController.text,
        'completed': false,
        'day': _selectedDay,
        'time': _timeController.text,
      });
      _taskController.clear();
      _timeController.clear();
    }
  }

  void _toggleTaskCompletion(String taskId, bool completed) {
    _firestore.collection('tasks').doc(taskId).update({ //update task completion status
      'completed': completed,
    });
  }

  void _deleteTask(String taskId) { //delete task
    _firestore.collection('tasks').doc(taskId).delete();
  }
}