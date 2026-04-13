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

  // local map tracks which task tiles are expanded
  final Map<String, bool> _expandedTasks = {};

  // local map stores one controller per task for subtask input
  final Map<String, TextEditingController> _subtaskControllers = {};

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

  // return a controller for a specific task's subtask field
  TextEditingController _getSubtaskController(String taskId) {
    if (!_subtaskControllers.containsKey(taskId)) {
      _subtaskControllers[taskId] = TextEditingController();
    }
    return _subtaskControllers[taskId]!;
  }

  // add a nested subtask under a parent task
  Future<void> _addSubtask(Task parentTask) async {
    final controller = _getSubtaskController(parentTask.id);
    final String subtaskTitle = controller.text.trim();

    // block empty subtask submissions
    if (subtaskTitle.isEmpty) return;

    final Task newSubtask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: subtaskTitle,
      isCompleted: false,
      subtasks: [],
    );

    final List<Task> updatedSubtasks = [...parentTask.subtasks, newSubtask];

    final Task updatedTask = Task(
      id: parentTask.id,
      title: parentTask.title,
      isCompleted: parentTask.isCompleted,
      subtasks: updatedSubtasks,
    );

    await _taskService.updateTask(updatedTask);

    // clear input after successful add
    controller.clear();
  }

  // remove a subtask from a parent task
  Future<void> _deleteSubtask(Task parentTask, String subtaskId) async {
    final List<Task> updatedSubtasks = parentTask.subtasks
        .where((subtask) => subtask.id != subtaskId)
        .toList();

    final Task updatedTask = Task(
      id: parentTask.id,
      title: parentTask.title,
      isCompleted: parentTask.isCompleted,
      subtasks: updatedSubtasks,
    );

    await _taskService.updateTask(updatedTask);
  }

  @override
  void dispose() {
    // dispose main controller to prevent memory leaks
    _taskController.dispose();

    // dispose all subtask controllers
    for (final controller in _subtaskControllers.values) {
      controller.dispose();
    }

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
                    final bool isExpanded = _expandedTasks[task.id] ?? false;
                    final subtaskController = _getSubtaskController(task.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          // main task row
                          ListTile(
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

                            // action buttons for expand and delete
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // expand button reveals nested subtasks
                                IconButton(
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _expandedTasks[task.id] = !isExpanded;
                                    });
                                  },
                                ),

                                // delete button removes task
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteTask(task.id),
                                ),
                              ],
                            ),
                          ),

                          // expanded section shows subtasks and input
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  // subtask input row
                                  Row(
                                    children: [
                                      // text field for entering subtask title
                                      Expanded(
                                        child: TextField(
                                          controller: subtaskController,
                                          decoration: const InputDecoration(
                                            hintText: 'Add a subtask',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // add button submits new subtask
                                      ElevatedButton(
                                        onPressed: () => _addSubtask(task),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // show nested subtasks if they exist
                                  if (task.subtasks.isEmpty)
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('No subtasks yet'),
                                    ),

                                  // render each subtask row
                                  ...task.subtasks.map((subtask) {
                                    return ListTile(
                                      contentPadding: const EdgeInsets.only(
                                        left: 16,
                                        right: 0,
                                      ),
                                      leading: const Icon(
                                        Icons.subdirectory_arrow_right,
                                      ),
                                      title: Text(subtask.title),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteSubtask(
                                          task,
                                          subtask.id,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
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