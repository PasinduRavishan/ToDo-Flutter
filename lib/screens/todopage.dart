import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Task {
  String id;
  String title;
  String desc;

  Task({ required this.id, required this.title, this.desc = '' });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'desc': desc,
  };

  static Task fromJson(Map<String, dynamic> j) {
    return Task(
      id: j['id'] as String,
      title: j['title'] as String,
      desc: j['desc'] ?? '',
    );
  }
}

class TodoPage extends StatefulWidget {
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Task> tasks = [];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('tasks');
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        setState(() {
          tasks = decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      // If stored data is corrupted or unreadable, we ignore and start with empty list
      setState(() => tasks = []);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _addTask() {
    _titleCtrl.clear();
    _descCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: _descCtrl, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(onPressed: () {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return; // simple validation
              final t = Task(
                id: DateTime.now().toIso8601String(),
                title: title,
                desc: _descCtrl.text.trim(),
              );
              setState(() => tasks.add(t));
              _saveTasks();
              Navigator.pop(context);
            }, child: Text('Add')),
          ],
        );
      },
    );
  }

  void _editTask(Task task) {
    _titleCtrl.text = task.title;
    _descCtrl.text = task.desc;

    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Edit Task'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _titleCtrl),
          TextField(controller: _descCtrl),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            setState(() {
              task.title = title;
              task.desc = _descCtrl.text.trim();
            });
            _saveTasks();
            Navigator.pop(context);
          }, child: Text('Save')),
        ],
      );
    });
  }

  void _deleteTask(Task t) {
    setState(() => tasks.removeWhere((x) => x.id == t.id));
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter To-Do')),
      body: tasks.isEmpty
          ? Center(child: Text('No tasks yet. Tap + to add one.'))
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: task.desc.isNotEmpty ? Text(task.desc) : null,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(Icons.edit), onPressed: () => _editTask(task)),
              IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteTask(task)),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
      ),
    );
  }
}
