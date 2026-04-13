// model represents a single task document in Firestore
class Task {
  String id;
  String title;
  bool isCompleted;
  List<Task> subtasks;

  // constructor for creating a task object
  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.subtasks = const [],
  });

  // convert Firestore map -> Task object
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,

      // convert list of maps into list of Task objects (recursive)
      subtasks: (data['subtasks'] as List<dynamic>? ?? [])
          .map((subtask) => Task.fromMap(subtask, subtask['id']))
          .toList(),
    );
  }

  // convert Task object -> Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,

      // convert subtasks into list of maps
      'subtasks': subtasks.map((task) => {
            'id': task.id,
            'title': task.title,
            'isCompleted': task.isCompleted,
            'subtasks': task.subtasks.map((t) => t.toMap()).toList(),
          }).toList(),
    };
  }
}