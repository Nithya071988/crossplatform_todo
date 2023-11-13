import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    'JPa2Ml9uiwNVOa3Xla2vaIAgCnMLqTLB5tZQZJnC',
    'https://parseapi.back4app.com',
    clientKey: 'ZaqJopCJBniOE4yVME17SF6Sc21zZumh21ld09zC',
    autoSendSessionId: true,
    debug: true,
  );

  runApp(MyApp());
}

class Task {
  String objectId;
  String title;
  String description;
  bool isCompleted;

  Task({
    required this.objectId,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}

class TaskService {
  static Future<List<Task>> getTasks() async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..orderByDescending('createdAt');

    final response = await queryBuilder.query();
    if (response.success && response.results != null) {
      return response.results!
          .map((parseObject) => Task(
        objectId: parseObject.objectId!,
        title: parseObject.get('title'),
        description: parseObject.get('description'),
        isCompleted: parseObject.get('isCompleted'),
      ))
          .toList();
    } else {
      throw Exception('Failed to fetch tasks');
    }
  }

  static Future<void> addTask(Task task) async {
    final parseObject = ParseObject('Task')
      ..set('title', task.title)
      ..set('description', task.description)
      ..set('isCompleted', task.isCompleted);

    final response = await parseObject.save();
    if (!response.success) {
      throw Exception('Failed to add task');
    }
  }

  static Future<void> updateTask(Task task) async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..whereEqualTo('objectId', task.objectId);

    final response = await queryBuilder.query();
    if (response.success && response.results != null) {
      final taskObject = response.results!.first;
      taskObject.set('title', task.title);
      taskObject.set('description', task.description);
      taskObject.set('isCompleted', task.isCompleted);

      await taskObject.save();
    } else {
      throw Exception('Failed to update task');
    }
  }

  static Future<void> deleteTask(String objectId) async {
    final task = ParseObject('Task')..set('objectId', objectId);

    final response = await task.delete();
    if (!response.success) {
      throw Exception('Failed to delete task');
    }
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  _fetchTasks() async {
    try {
      final fetchedTasks = await TaskService.getTasks();
      setState(() {
        tasks = fetchedTasks;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index].title),
            subtitle: Text(tasks[index].description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editTask(context, tasks[index]);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteTask(tasks[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTask(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  _addTask(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await TaskService.addTask(Task(
                    objectId: '',
                    title: titleController.text,
                    description: descriptionController.text,
                  ));
                  await _fetchTasks();
                  Navigator.pop(context);
                } catch (e) {
                  print('Error adding task: $e');
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  _editTask(BuildContext context, Task task) async {
    TextEditingController titleController =
    TextEditingController(text: task.title);
    TextEditingController descriptionController =
    TextEditingController(text: task.description);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await TaskService.updateTask(Task(
                    objectId: task.objectId,
                    title: titleController.text,
                    description: descriptionController.text,
                    isCompleted: task.isCompleted,
                  ));
                  await _fetchTasks();
                  Navigator.pop(context);
                } catch (e) {
                  print('Error updating task: $e');
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  _deleteTask(Task task) async {
    try {
      await TaskService.deleteTask(task.objectId);
      await _fetchTasks();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}