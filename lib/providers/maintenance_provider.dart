import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_task.dart';

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceTask> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  List<MaintenanceTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MaintenanceTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  Future<void> fetchTasks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _tasks = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _supabase
          .from('maintenance_tasks')
          .select()
          .eq('user_id', userId);

      _tasks = (data as List).map((item) => MaintenanceTask.fromJson(item)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(MaintenanceTask task) async {
    try {
      _errorMessage = null;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      final taskData = task.toJson();
      taskData['user_id'] = userId;

      await _supabase.from('maintenance_tasks').insert(taskData);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error adding task: $e');
      return false;
    }
  }

  Future<bool> updateTask(String taskId, MaintenanceTask task) async {
    try {
      _errorMessage = null;
      final taskData = task.toJson();
      await _supabase.from('maintenance_tasks').update(taskData).eq('id', taskId);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> removeTask(String taskId) async {
    try {
      _errorMessage = null;
      await _supabase.from('maintenance_tasks').delete().eq('id', taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error removing task: $e');
      return false;
    }
  }

  Future<bool> completeTask(String taskId) async {
    try {
      _errorMessage = null;
      await _supabase
          .from('maintenance_tasks')
          .update({
            'is_completed': true,
            'completed_date': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error completing task: $e');
      return false;
    }
  }

  List<MaintenanceTask> getTasksByPlantId(String plantId) {
    return _tasks.where((t) => t.plantId == plantId).toList();
  }
}
