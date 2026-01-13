import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';

class PlantProvider with ChangeNotifier {
  List<Plant> _plants = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  List<Plant> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPlants() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _plants = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _supabase
          .from('plants')
          .select()
          .eq('user_id', userId);

      _plants = (data as List).map((item) => Plant.fromJson(item)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching plants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPlant(Plant plant) async {
    try {
      _errorMessage = null;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      final plantData = plant.toJson();
      plantData['user_id'] = userId;

      await _supabase.from('plants').insert(plantData);
      await fetchPlants();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error adding plant: $e');
      return false;
    }
  }

  Future<bool> updatePlant(String plantId, Plant plant) async {
    try {
      _errorMessage = null;
      final plantData = plant.toJson();
      await _supabase.from('plants').update(plantData).eq('id', plantId);
      await fetchPlants();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating plant: $e');
      return false;
    }
  }

  Future<bool> removePlant(String plantId) async {
    try {
      _errorMessage = null;
      await _supabase.from('plants').delete().eq('id', plantId);
      _plants.removeWhere((p) => p.id == plantId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error removing plant: $e');
      return false;
    }
  }

  Plant? getPlantById(String plantId) {
    try {
      return _plants.firstWhere((p) => p.id == plantId);
    } catch (e) {
      return null;
    }
  }
}
