import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

// stateful screen for displaying and managing tasks
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // controller for reading task input text
  final TextEditingController _taskController = TextEditingController();

  // service instance used for firestore actions
  final TaskService _taskService = TaskService();

  // add a new task to firestore
  Future<void> _addTask() async {
    final String title = _taskController.text.trim();

    // block empty task submissions
    if (title.isEmpty) return;

    final Task newTask = Task(
      id: '',
      title: title,
      isCompleted: false,
      subtasks: [],
    );

    await _taskService.addTask(newTask);

    // clear input after successful add
    _taskController.clear();
  }

  // toggle task completion and update firestore
  Future<void> _toggleTask(Task task) async {
    final Task updatedTask = Task(
      id: task.id,
      title: task.title,
      isCompleted: !task.isCompleted,
      subtasks: task.subtasks,
    );

    await _taskService.updateTask(updatedTask);
  }

  // delete a task from firestore
  Future<void> _deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }

  @override
  void dispose() {
    // dispose controller to prevent memory leaks
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // input row for adding new tasks
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // text field for entering task title
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // add button submits new task
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // streambuilder listens for live firestore updates
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.streamTasks(),
              builder: (context, snapshot) {
                // show loading spinner while connecting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // show error text if stream fails
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong while loading tasks'),
                  );
                }

                final List<Task> tasks = snapshot.data ?? [];

                // show empty state when no tasks exist
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('No tasks yet. Add one above!'),
                  );
                }

                // show live task list
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final Task task = tasks[index];

                    return ListTile(
                      // checkbox toggles completion state
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => _toggleTask(task),
                      ),

                      // task title with strike-through when completed
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),

                      // delete button removes task
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTask(task.id),
                      ),
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
}