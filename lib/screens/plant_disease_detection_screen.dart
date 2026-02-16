import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../config/theme.dart';
import '../models/plant.dart';
import '../providers/plant_provider.dart';
import '../services/disease_detection_service.dart';

class PlantDiseaseDetectionScreen extends StatefulWidget {
  const PlantDiseaseDetectionScreen({super.key});

  @override
  State<PlantDiseaseDetectionScreen> createState() =>
      _PlantDiseaseDetectionScreenState();
}

class _PlantDiseaseDetectionScreenState
    extends State<PlantDiseaseDetectionScreen> {
  Plant? _selectedPlant;
  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  String? _diseaseResult;
  double? _confidenceScore;
  String? _diseaseDescription;
  List<String>? _treatments;
  String? _detectedPlant;
  bool? _isHealthy;

  final ImagePicker _imagePicker = ImagePicker();
  final DiseaseDetectionService _diseaseService = DiseaseDetectionService();

  @override
  void initState() {
    super.initState();
    // Fetch plants on screen load
    Future.microtask(() {
      context.read<PlantProvider>().fetchPlants();
    });
    // Initialize the TFLite model
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _diseaseService.initialize();
      print('✅ Disease detection model initialized');
    } catch (e) {
      print('❌ Failed to initialize model: $e');
    }
  }

  @override
  void dispose() {
    _diseaseService.dispose();
    super.dispose();
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageBytes = imageBytes;
        });
      }
    } catch (e) {
      print('❌ Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageBytes = imageBytes;
        });
      }
    } catch (e) {
      print('❌ Gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Analyze image for disease using TFLite model
  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _selectedPlant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plant and capture/upload an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      print('🔍 Starting disease analysis with TFLite model...');
      
      // Run inference using the TFLite model
      final result = await _diseaseService.detectDisease(_imageBytes!);
      
      // Check if leaf detection failed
      if (result['error'] == true && result['errorType'] == 'no_leaf_detected') {
        setState(() {
          _isAnalyzing = false;
        });
        
        if (mounted) {
          // Show alert dialog for no leaf detected
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  const Text('No Leaf Detected'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['message'] ?? 'The image does not appear to contain a plant leaf.',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please upload a clear image of a plant leaf for disease detection.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetAnalysis();
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      setState(() {
        _detectedPlant = result['plant'];
        _diseaseResult = result['isHealthy'] ? 'Healthy' : result['disease'];
        _confidenceScore = result['confidence'];
        _diseaseDescription = result['description'];
        _treatments = List<String>.from(result['treatments'] ?? []);
        _isHealthy = result['isHealthy'];
        _analysisComplete = true;
        _isAnalyzing = false;
      });

      print('✅ Disease analysis complete');
      print('Detected Plant: $_detectedPlant');
      print('Disease: $_diseaseResult');
      print('Confidence: $_confidenceScore%');
      print('Is Healthy: $_isHealthy');
    } catch (e) {
      print('❌ Analysis error: $e');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _analysisComplete = false;
      _diseaseResult = null;
      _confidenceScore = null;
      _diseaseDescription = null;
      _treatments = null;
      _detectedPlant = null;
      _isHealthy = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disease Detection',
                              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Identify plant diseases from leaf images',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Plant
                  _buildStepCard(
                    context,
                    step: 1,
                    title: 'Select Your Plant',
                    content: _buildPlantSelection(),
                  ),
                  const SizedBox(height: 20),

                  // Step 2: Capture/Upload Image
                  _buildStepCard(
                    context,
                    step: 2,
                    title: 'Capture or Upload Leaf Image',
                    content: _buildImageCapture(),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Analyze
                  if (_selectedImage != null && _selectedPlant != null)
                    _buildStepCard(
                      context,
                      step: 3,
                      title: 'Analyze Image',
                      content: _buildAnalysisButton(),
                    ),
                  const SizedBox(height: 20),

                  // Results Section
                  if (_analysisComplete) _buildResultsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step Card Builder
  Widget _buildStepCard(
    BuildContext context, {
    required int step,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  // Plant Selection Widget
  Widget _buildPlantSelection() {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, _) {
        if (plantProvider.plants.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.eco,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No plants found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add plants to your library first',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedPlant != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentGreen, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlant!.nickname ?? _selectedPlant!.plantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_selectedPlant!.scientificName != null)
                            Text(
                              _selectedPlant!.scientificName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedPlant = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showPlantSelectionSheet(plantProvider),
                  child: const Text('Change Plant'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: plantProvider.plants.length,
                  itemBuilder: (context, index) {
                    final plant = plantProvider.plants[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlant = plant),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentGreen,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, color: accentGreen, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              plant.nickname ?? plant.plantName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // Show plant selection bottom sheet
  void _showPlantSelectionSheet(PlantProvider plantProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Plant',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: plantProvider.plants.length,
                  itemBuilder: (context, index) {
                    final plant = plantProvider.plants[index];
                    return ListTile(
                      leading: Icon(Icons.eco, color: accentGreen),
                      title: Text(plant.nickname ?? plant.plantName),
                      subtitle: Text(
                        plant.scientificName ?? 'Unknown',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      trailing: Icon(
                        _selectedPlant?.id == plant.id
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: accentGreen,
                      ),
                      onTap: () {
                        setState(() => _selectedPlant = plant);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Image Capture Widget
  Widget _buildImageCapture() {
    if (_selectedImage == null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No Image Selected',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture a leaf or upload from gallery',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentGreen,
                width: 2,
              ),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose Different'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  // Analysis Button Widget
  Widget _buildAnalysisButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        icon: _isAnalyzing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isAnalyzing ? Colors.white : primaryGreen,
                  ),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isAnalyzing ? 'Analyzing...' : 'Analyze for Disease',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isAnalyzing ? Colors.grey[400] : primaryGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // Results Section
  Widget _buildResultsSection() {
    final isHealthy = _isHealthy ?? false;
    final resultColor = isHealthy ? Colors.green[600] : Colors.red[600];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disease Detection Result Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHealthy 
                  ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                  : [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isHealthy ? Colors.green : Colors.red, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle : Icons.warning_rounded,
                    color: resultColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analysis Complete',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Detected Plant
              if (_detectedPlant != null) ...[
                Text(
                  'Detected Plant',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _detectedPlant!,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              // Disease Name
              Text(
                isHealthy ? 'Plant Status' : 'Detected Disease',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _diseaseResult ?? 'Unknown',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
              ),
              const SizedBox(height: 12),
              // Confidence Score
              Row(
                children: [
                  Icon(Icons.precision_manufacturing,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence Score',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_confidenceScore?.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Confidence Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_confidenceScore ?? 0) / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    resultColor!,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Disease Description
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _diseaseDescription ?? 'No description available',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Treatment Recommendations
        Text(
          'Recommended Treatment',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._treatments?.map((treatment) {
              int index = _treatments!.indexOf(treatment) + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          treatment,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList() ??
            [],
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetAnalysis,
                icon: const Icon(Icons.refresh),
                label: const Text('Analyze Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Save disease report to database
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report saved to disease history'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
