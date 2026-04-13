import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

// service class handles all firestore task operations
class TaskService {
  // reference to tasks collection in firestore
  final CollectionReference _tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  // add a new task document to firestore
  Future<void> addTask(Task task) async {
    await _tasksCollection.add(task.toMap());
  }

  // return a real-time stream of task objects from firestore
  Stream<List<Task>> streamTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromMap(data, doc.id);
      }).toList();
    });
  }

  // update an existing task document in firestore
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }

  // delete a task document from firestore
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }
}