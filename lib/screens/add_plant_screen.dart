import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../services/plant_identification_service.dart';
import '../models/plant.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // State variables
  File? _selectedImage;
  Uint8List? _imageBytes;  // Store image bytes for web compatibility
  Map<String, dynamic>? _identifiedPlant;
  bool _isLoading = false;
  bool _isIdentifying = false;
  String? _errorMessage;
  String? _successMessage;

  // Controllers for user input
  late TextEditingController _nicknameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Pick image from camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImage = File(photo.path);
          _imageBytes = bytes;
          _identifiedPlant = null;
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to take photo: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = bytes;
          _identifiedPlant = null;
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  /// Identify plant using the selected image
  Future<void> _identifyPlant() async {
    if (_imageBytes == null) {
      setState(() => _errorMessage = 'Please select an image first');
      return;
    }

    setState(() {
      _isIdentifying = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Identifying plant from image...');

      final plantData =
          await PlantIdentificationService.identifyPlantFromBytes(_imageBytes!);

      if (plantData != null) {
        print('✅ Plant identified: ${plantData['plant_name']}');

        // Pre-populate nickname with plant name
        _nicknameController.text = plantData['plant_name'] ?? '';

        setState(() {
          _identifiedPlant = plantData;
          _isIdentifying = false;
        });

        // Show confirmation dialog
        _showConfirmationDialog();
      } else {
        setState(() {
          _errorMessage = 'Could not identify plant. Please try another image.';
          _isIdentifying = false;
        });
      }
    } catch (e) {
      print('❌ Error identifying plant: $e');
      setState(() {
        _errorMessage = 'Failed to identify plant: $e';
        _isIdentifying = false;
      });
    }
  }

  /// Show confirmation dialog with identified plant details
  void _showConfirmationDialog() {
    if (_identifiedPlant == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Plant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant image preview
              if (_imageBytes != null)
                SizedBox(
                  height: 180,
                  width: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Plant name
              Text(
                'Plant: ${_identifiedPlant!['plant_name'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              // Scientific name
              if (_identifiedPlant!['scientific_name'] != null)
                Text(
                  'Scientific: ${_identifiedPlant!['scientific_name']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),

              // Confidence
              Text(
                'Confidence: ${(_identifiedPlant!['confidence'] ?? 0).toStringAsFixed(1)}%',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: accentGreen),
              ),
              const SizedBox(height: 16),

              // Nickname field
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname (Optional)',
                  hintText: 'e.g., Tom\'s Tomato',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Location field
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Balcony, Garden',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Care info preview
              Text(
                'Care Tips:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              _buildCareInfoPreview(),
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
              Navigator.pop(context);
              _savePlantToDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
            ),
            child: const Text('Add Plant'),
          ),
        ],
      ),
    );
  }

  /// Build care info preview widget
  Widget _buildCareInfoPreview() {
    if (_identifiedPlant == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCareRow('💧 Water:', _identifiedPlant!['watering']),
          const SizedBox(height: 4),
          _buildCareRow('☀️ Sunlight:', _identifiedPlant!['sunlight']),
          const SizedBox(height: 4),
          _buildCareRow('🌡️ Temperature:',
              _identifiedPlant!['temperature'] ?? 'Not specified'),
        ],
      ),
    );
  }

  /// Build care row widget
  Widget _buildCareRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? 'Not specified',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// Save plant to Supabase database
  Future<void> _savePlantToDatabase() async {
    if (_identifiedPlant == null || _selectedImage == null) {
      setState(() => _errorMessage = 'Missing plant data');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('📤 Uploading plant image...');

      // Step 1: Convert image to base64 for temporary storage
      // Using placeholder URL for now since storage has RLS issues
      final imageUrl = 'https://via.placeholder.com/300?text=Plant+Image';
      print('🔗 Image URL: $imageUrl (placeholder)');

      print('🔄 Saving plant to database...');

      // Step 2: Save plant data to Supabase
      final plantId = const Uuid().v4();
      final plant = Plant(
        id: plantId,
        userId: userId,
        plantName: _identifiedPlant!['plant_name'] ?? 'Unknown Plant',
        scientificName: _identifiedPlant!['scientific_name'],
        nickname: _nicknameController.text.isNotEmpty
            ? _nicknameController.text
            : null,
        imageUrl: imageUrl,
        confidence: _identifiedPlant!['confidence']?.toDouble() ?? 0.0,
        careWater: _identifiedPlant!['watering'],
        careSunlight: _identifiedPlant!['sunlight'],
        careTemperature: _identifiedPlant!['temperature'],
        healthStatus: 'healthy',
        createdAt: DateTime.now(),
      );

      await _supabase.from('plants').insert(plant.toJson());

      print('✅ Plant saved successfully to database');
      print('📋 Saved plant data: ${plant.toJson()}');

      setState(() {
        _isLoading = false;
        _successMessage =
            'Plant "${plant.plantName}" added successfully! 🌿';
        _selectedImage = null;
        _identifiedPlant = null;
        _nicknameController.clear();
        _locationController.clear();
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage ?? 'Plant added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Return to previous screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      print('❌ Error saving plant: $e');
      print('🔍 Error type: ${e.runtimeType}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save plant: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Error saving plant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text('Add Plant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Success message
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null) const SizedBox(height: 16),

            // Image preview or selection area
            if (_selectedImage != null && _imageBytes != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isIdentifying
                          ? null
                          : _identifyPlant,
                      icon: _isIdentifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        _isIdentifying
                            ? 'Identifying Plant...'
                            : 'Identify Plant',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryGreen, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: primaryGreen.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a Plant Image',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: primaryGreen),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose from camera or gallery',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textGray),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Image selection buttons
            if (_selectedImage == null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

            if (_selectedImage != null) const SizedBox(height: 20),

            // Identified plant details (if available)
            if (_identifiedPlant != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identified Plant',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPlantDetailCard(
                    'Common Name',
                    _identifiedPlant!['plant_name'] ?? 'Unknown',
                    Icons.eco,
                  ),
                  const SizedBox(height: 12),
                  _buildPlantDetailCard(
                    'Scientific Name',
                    _identifiedPlant!['scientific_name'] ?? 'Not available',
                    Icons.book,
                  ),
                  const SizedBox(height: 12),
                  _buildPlantDetailCard(
                    'Confidence',
                    '${(_identifiedPlant!['confidence'] ?? 0).toStringAsFixed(1)}%',
                    Icons.verified,
                  ),
                  const SizedBox(height: 12),
                  _buildPlantDetailCard(
                    'Watering',
                    _identifiedPlant!['watering'] ?? 'Not specified',
                    Icons.opacity,
                  ),
                  const SizedBox(height: 12),
                  _buildPlantDetailCard(
                    'Sunlight',
                    _identifiedPlant!['sunlight'] ?? 'Not specified',
                    Icons.wb_sunny,
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: primaryGreen),
                    const SizedBox(height: 12),
                    Text(
                      'Saving your plant...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build plant detail card widget
  Widget _buildPlantDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
