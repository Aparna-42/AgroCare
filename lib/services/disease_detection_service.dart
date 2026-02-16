import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui' as ui;
import 'treatment_service.dart';
import 'leaf_detection_service.dart';

/// Service for plant disease detection using TFLite model
class DiseaseDetectionService {
  static const String _modelPath = 'assets/models/plant_disease_detector_trained.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  
  static const int _inputSize = 224; // Model expects 224x224 images
  static const int _numClasses = 38;
  
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  /// Initialize the TFLite model and load labels
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Loading TFLite model...');
      
      // Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      
      _isInitialized = true;
      print('✅ Disease detection model loaded successfully');
      print('📋 Loaded ${_labels!.length} class labels');
    } catch (e) {
      print('❌ Error loading model: $e');
      rethrow;
    }
  }

  /// Check if the model is initialized
  bool get isInitialized => _isInitialized;

  /// Get the list of supported plants from the labels
  List<String> getSupportedPlants() {
    if (_labels == null) return [];
    
    final plants = <String>{};
    for (final label in _labels!) {
      // Extract plant name (before ___) 
      final parts = label.split('___');
      if (parts.isNotEmpty) {
        // Convert to readable format
        String plantName = parts[0]
            .replaceAll('_', ' ')
            .replaceAll(',', ',');
        plants.add(plantName);
      }
    }
    return plants.toList()..sort();
  }

  /// Check if image contains a leaf before detection
  /// Returns LeafDetectionResult with isLeaf, confidence, and reason
  Future<LeafDetectionResult> checkForLeaf(Uint8List imageBytes) async {
    return await LeafDetectionService.detectLeaf(imageBytes);
  }

  /// Detect disease from image bytes
  /// Returns a map with 'label', 'disease', 'plant', 'confidence', 'isHealthy'
  /// Set skipLeafCheck to true to bypass leaf detection (not recommended)
  Future<Map<String, dynamic>> detectDisease(Uint8List imageBytes, {bool skipLeafCheck = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔍 Starting disease detection...');
      
      // Step 1: Check if image contains a leaf (unless skipped)
      if (!skipLeafCheck) {
        final leafCheck = await LeafDetectionService.detectLeaf(imageBytes);
        print('🍃 Leaf check result: ${leafCheck.toString()}');
        
        if (!leafCheck.isLeaf) {
          // Return error result indicating no leaf detected
          return {
            'error': true,
            'errorType': 'no_leaf_detected',
            'message': leafCheck.reason,
            'label': 'No Leaf',
            'plant': 'Unknown',
            'disease': 'N/A',
            'confidence': 0.0,
            'isHealthy': false,
            'description': leafCheck.reason,
            'treatments': <String>[],
            'leafDetection': {
              'isLeaf': leafCheck.isLeaf,
              'confidence': leafCheck.confidence,
              'reason': leafCheck.reason,
              'greenRatio': leafCheck.greenRatio,
              'plantColorRatio': leafCheck.plantColorRatio,
              'skinToneRatio': leafCheck.skinToneRatio,
            }
          };
        }
      }
      
      // Step 2: Proceed with disease detection
      // Decode and preprocess image
      final inputData = await _preprocessImage(imageBytes);
      
      // Create output buffer for 38 classes
      var outputBuffer = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);
      
      // Run inference
      print('🤖 Running TFLite inference...');
      _interpreter!.run(inputData, outputBuffer);
      
      // Get results
      List<double> outputs = outputBuffer[0].cast<double>();
      
      // Apply softmax to convert to probabilities
      outputs = _softmax(outputs);
      
      // Find the class with highest probability
      int maxIndex = 0;
      double maxProb = outputs[0];
      for (int i = 1; i < outputs.length; i++) {
        if (outputs[i] > maxProb) {
          maxProb = outputs[i];
          maxIndex = i;
        }
      }
      
      final predictedLabel = _labels![maxIndex];
      final confidence = (maxProb * 100).toStringAsFixed(1);
      
      // Parse the label to get plant and disease
      final parts = predictedLabel.split('___');
      
      // Keep original names with underscores for database query
      final plantNameRaw = parts[0];
      final diseaseNameRaw = parts.length > 1 ? parts[1] : 'Unknown';
      
      // Format for display (with spaces)
      final plantName = plantNameRaw.replaceAll('_', ' ').replaceAll(',', ',');
      final diseaseName = diseaseNameRaw.replaceAll('_', ' ');
      
      final isHealthy = diseaseName.toLowerCase() == 'healthy';
      
      print('✅ Detection complete:');
      print('   Plant: $plantName');
      print('   Disease: $diseaseName');
      print('   Confidence: $confidence%');
      print('   Is Healthy: $isHealthy');
      
      // Get top 3 predictions for debugging
      final sortedIndices = List.generate(outputs.length, (i) => i)
        ..sort((a, b) => outputs[b].compareTo(outputs[a]));
      
      print('   Top 3 predictions:');
      for (int i = 0; i < 3 && i < sortedIndices.length; i++) {
        final idx = sortedIndices[i];
        print('   ${i + 1}. ${_labels![idx]}: ${(outputs[idx] * 100).toStringAsFixed(2)}%');
      }
      
      // Fetch treatment suggestions from database using raw names with underscores
      final treatments = await _getTreatmentsFromDatabase(plantNameRaw, diseaseNameRaw);
      
      return {
        'label': predictedLabel,
        'plant': plantName,
        'disease': diseaseName,
        'confidence': double.parse(confidence),
        'isHealthy': isHealthy,
        'description': _getDiseaseDescription(predictedLabel),
        'treatments': treatments,
      };
    } catch (e) {
      print('❌ Disease detection error: $e');
      rethrow;
    }
  }

  /// Fetch treatment suggestions from Supabase database
  Future<List<String>> _getTreatmentsFromDatabase(String plantNameRaw, String diseaseNameRaw) async {
    try {
      // Use raw names with underscores for database query (matches DB format)
      print('🔍 Fetching treatment for DB query: $plantNameRaw - $diseaseNameRaw');
      
      final treatments = await TreatmentService.getTreatmentSuggestions(
        plantNameRaw,
        diseaseNameRaw,
      );
      
      if (treatments.isNotEmpty && !treatments.first.contains('Consult with a local agricultural expert')) {
        print('✅ Found treatment from database');
        return treatments;
      }
      
      // Fallback to hardcoded treatments if database doesn't have it
      print('⚠️ Using fallback treatment (not found in DB)');
      return _getTreatments('${plantNameRaw}___$diseaseNameRaw');
    } catch (e) {
      print('❌ Error fetching treatment from database: $e');
      // Fallback to hardcoded if database fetch fails
      return _getTreatments('${plantNameRaw}___$diseaseNameRaw');
    }
  }

  /// Preprocess image for the model
  /// Model expects: [1, 224, 224, 3] with values normalized to [0, 1]
  Future<List<List<List<List<double>>>>> _preprocessImage(Uint8List imageBytes) async {
    // Decode image
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: _inputSize,
      targetHeight: _inputSize,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    
    // Convert to byte data
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = byteData!.buffer.asUint8List();
    
    // Create input tensor [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixelIndex = (y * _inputSize + x) * 4; // RGBA format
            return [
              pixels[pixelIndex] / 255.0,     // R
              pixels[pixelIndex + 1] / 255.0, // G
              pixels[pixelIndex + 2] / 255.0, // B
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  /// Apply softmax to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expValues = logits.map((l) => _exp(l - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }

  /// Safe exponential function to prevent overflow
  double _exp(double x) {
    if (x > 700) return double.maxFinite;
    if (x < -700) return 0;
    return math.exp(x);
  }

  /// Get description for a disease
  String _getDiseaseDescription(String label) {
    final descriptions = {
      'Apple___Apple_scab': 'Apple scab is a fungal disease caused by Venturia inaequalis. It causes dark, scabby lesions on leaves and fruit.',
      'Apple___Black_rot': 'Black rot is a fungal disease that causes brown spots on leaves with concentric rings, and black, rotten areas on fruit.',
      'Apple___Cedar_apple_rust': 'Cedar apple rust is caused by the fungus Gymnosporangium juniperi-virginianae. It produces bright orange spots on leaves.',
      'Apple___healthy': 'Your apple plant appears healthy with no visible signs of disease.',
      'Blueberry___healthy': 'Your blueberry plant appears healthy with no visible signs of disease.',
      'Cherry_(including_sour)___Powdery_mildew': 'Powdery mildew appears as white, powdery spots on leaves and stems. It can reduce fruit quality.',
      'Cherry_(including_sour)___healthy': 'Your cherry plant appears healthy with no visible signs of disease.',
      'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': 'Gray leaf spot causes rectangular lesions on corn leaves. It thrives in humid conditions.',
      'Corn_(maize)___Common_rust_': 'Common rust produces small, reddish-brown pustules on both leaf surfaces.',
      'Corn_(maize)___Northern_Leaf_Blight': 'Northern leaf blight causes long, cigar-shaped gray-green lesions on leaves.',
      'Corn_(maize)___healthy': 'Your corn plant appears healthy with no visible signs of disease.',
      'Grape___Black_rot': 'Black rot causes circular tan spots on leaves and shriveled, black "mummified" fruit.',
      'Grape___Esca_(Black_Measles)': 'Esca causes tiger-stripe patterns on leaves and can lead to sudden vine collapse.',
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': 'Leaf blight causes angular brown spots on leaves, often with yellow halos.',
      'Grape___healthy': 'Your grape plant appears healthy with no visible signs of disease.',
      'Orange___Haunglongbing_(Citrus_greening)': 'Citrus greening is a bacterial disease spread by psyllids. It causes mottled yellowing of leaves and misshapen fruit.',
      'Peach___Bacterial_spot': 'Bacterial spot causes small, dark spots on leaves and fruit, often with a water-soaked appearance.',
      'Peach___healthy': 'Your peach plant appears healthy with no visible signs of disease.',
      'Pepper,_bell___Bacterial_spot': 'Bacterial spot causes raised, scab-like spots on leaves and fruit.',
      'Pepper,_bell___healthy': 'Your bell pepper plant appears healthy with no visible signs of disease.',
      'Potato___Early_blight': 'Early blight causes dark brown spots with concentric rings (target-like pattern) on older leaves.',
      'Potato___Late_blight': 'Late blight is a devastating disease causing water-soaked lesions that turn brown/black. It can destroy crops rapidly.',
      'Potato___healthy': 'Your potato plant appears healthy with no visible signs of disease.',
      'Raspberry___healthy': 'Your raspberry plant appears healthy with no visible signs of disease.',
      'Soybean___healthy': 'Your soybean plant appears healthy with no visible signs of disease.',
      'Squash___Powdery_mildew': 'Powdery mildew appears as white, powdery coating on leaves, reducing photosynthesis and plant vigor.',
      'Strawberry___Leaf_scorch': 'Leaf scorch causes purple spots that develop into irregular brown areas on leaves.',
      'Strawberry___healthy': 'Your strawberry plant appears healthy with no visible signs of disease.',
      'Tomato___Bacterial_spot': 'Bacterial spot causes small, dark, water-soaked spots on leaves and fruit.',
      'Tomato___Early_blight': 'Early blight causes dark spots with concentric rings on lower leaves first.',
      'Tomato___Late_blight': 'Late blight causes water-soaked gray-green spots that turn brown. Highly destructive.',
      'Tomato___Leaf_Mold': 'Leaf mold causes yellow spots on upper leaf surfaces with olive-green mold below.',
      'Tomato___Septoria_leaf_spot': 'Septoria causes small circular spots with dark borders and gray centers.',
      'Tomato___Spider_mites Two-spotted_spider_mite': 'Spider mites cause stippling on leaves and fine webbing. Leaves may turn yellow and dry.',
      'Tomato___Target_Spot': 'Target spot causes brown lesions with concentric rings, similar to a target pattern.',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus': 'TYLCV causes severe leaf curling, yellowing, and stunted growth. Spread by whiteflies.',
      'Tomato___Tomato_mosaic_virus': 'Mosaic virus causes mottled light/dark green patterns on leaves and reduced fruit quality.',
      'Tomato___healthy': 'Your tomato plant appears healthy with no visible signs of disease.',
    };
    
    return descriptions[label] ?? 'Disease detected. Please consult with an agricultural expert for more information.';
  }

  /// Get treatment recommendations for a disease
  List<String> _getTreatments(String label) {
    final treatments = {
      'Apple___Apple_scab': [
        'Remove and destroy fallen leaves',
        'Apply fungicide sprays during wet periods',
        'Improve air circulation by pruning',
        'Plant resistant varieties',
        'Avoid overhead irrigation',
      ],
      'Apple___Black_rot': [
        'Prune out infected branches',
        'Remove mummified fruit from trees',
        'Apply fungicide during the growing season',
        'Maintain good tree hygiene',
        'Ensure proper spacing between trees',
      ],
      'Apple___Cedar_apple_rust': [
        'Remove nearby cedar/juniper trees if possible',
        'Apply fungicide in spring',
        'Plant resistant apple varieties',
        'Prune infected branches',
        'Improve air circulation',
      ],
      'Apple___healthy': [
        'Continue regular watering schedule',
        'Apply balanced fertilizer as needed',
        'Monitor for pests and diseases',
        'Maintain good air circulation',
        'Prune annually for health',
      ],
      'Tomato___Early_blight': [
        'Remove infected leaves immediately',
        'Apply copper-based fungicide',
        'Mulch around plants to prevent soil splash',
        'Water at soil level, not on leaves',
        'Rotate crops annually',
        'Stake plants for better air flow',
      ],
      'Tomato___Late_blight': [
        'Remove and destroy infected plants immediately',
        'Apply fungicide preventively in humid weather',
        'Avoid overhead watering',
        'Ensure good air circulation',
        'Do not compost infected material',
        'Plant resistant varieties next season',
      ],
      'Tomato___Bacterial_spot': [
        'Remove infected plant parts',
        'Apply copper-based bactericide',
        'Avoid working with wet plants',
        'Use disease-free seeds',
        'Rotate crops for 2-3 years',
        'Improve drainage',
      ],
      'Tomato___Leaf_Mold': [
        'Improve air circulation',
        'Reduce humidity in greenhouse',
        'Remove infected leaves',
        'Apply fungicide if severe',
        'Space plants properly',
        'Water early in the day',
      ],
      'Tomato___Septoria_leaf_spot': [
        'Remove lower infected leaves',
        'Apply fungicide regularly',
        'Mulch to prevent soil splash',
        'Stake plants for air flow',
        'Rotate crops annually',
        'Avoid overhead watering',
      ],
      'Tomato___Spider_mites Two-spotted_spider_mite': [
        'Spray plants with strong water stream',
        'Apply insecticidal soap or neem oil',
        'Increase humidity around plants',
        'Remove heavily infested leaves',
        'Introduce predatory mites',
        'Avoid dusty conditions',
      ],
      'Tomato___Target_Spot': [
        'Remove infected leaves and debris',
        'Apply fungicide treatment',
        'Improve air circulation',
        'Avoid overhead irrigation',
        'Practice crop rotation',
        'Sanitize garden tools',
      ],
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus': [
        'Remove and destroy infected plants',
        'Control whitefly population',
        'Use reflective mulches',
        'Apply insecticides for whiteflies',
        'Plant resistant varieties',
        'Use row covers for protection',
      ],
      'Tomato___Tomato_mosaic_virus': [
        'Remove and destroy infected plants',
        'Wash hands before handling plants',
        'Disinfect tools with bleach solution',
        'Do not smoke near plants (TMV can spread from tobacco)',
        'Use virus-free seeds',
        'Control aphid population',
      ],
      'Tomato___healthy': [
        'Continue regular watering schedule',
        'Apply balanced tomato fertilizer',
        'Stake or cage plants for support',
        'Remove suckers for better fruit',
        'Monitor regularly for pests',
        'Harvest ripe fruit promptly',
      ],
      'Potato___Early_blight': [
        'Remove infected leaves',
        'Apply fungicide preventively',
        'Rotate crops for 2-3 years',
        'Use certified disease-free seed potatoes',
        'Ensure adequate plant nutrition',
        'Hill soil around plants',
      ],
      'Potato___Late_blight': [
        'Destroy infected plants immediately',
        'Apply fungicide before symptoms appear',
        'Avoid overhead irrigation',
        'Harvest only in dry conditions',
        'Store potatoes in cool, dry place',
        'Do not save seed from infected crop',
      ],
      'Potato___healthy': [
        'Continue regular hilling of soil',
        'Water consistently but avoid overwatering',
        'Apply balanced fertilizer',
        'Monitor for Colorado potato beetles',
        'Harvest when tops die back',
        'Cure potatoes before storage',
      ],
      'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': [
        'Plant resistant hybrids',
        'Rotate crops with non-host plants',
        'Apply fungicide if severe',
        'Improve air circulation',
        'Manage crop residue',
        'Avoid late planting',
      ],
      'Corn_(maize)___Common_rust_': [
        'Plant resistant varieties',
        'Apply fungicide if needed',
        'Plant early to avoid peak rust periods',
        'Monitor fields regularly',
        'Ensure adequate plant nutrition',
        'Remove volunteer corn plants',
      ],
      'Corn_(maize)___Northern_Leaf_Blight': [
        'Use resistant hybrids',
        'Rotate crops annually',
        'Apply foliar fungicide',
        'Manage crop residue',
        'Ensure balanced fertility',
        'Scout fields regularly',
      ],
      'Corn_(maize)___healthy': [
        'Continue regular fertilization',
        'Ensure adequate water especially at silking',
        'Monitor for pests like corn borers',
        'Control weeds',
        'Scout for diseases regularly',
        'Harvest at proper moisture content',
      ],
      'Grape___Black_rot': [
        'Remove mummified berries and infected leaves',
        'Apply fungicide before bloom',
        'Prune for good air circulation',
        'Control weeds around vines',
        'Avoid overhead irrigation',
        'Use resistant varieties',
      ],
      'Grape___Esca_(Black_Measles)': [
        'Prune out infected wood',
        'Protect pruning wounds',
        'Avoid stress to vines',
        'Remove severely affected vines',
        'Improve vineyard drainage',
        'Avoid late-season irrigation stress',
      ],
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': [
        'Remove infected leaves',
        'Apply appropriate fungicide',
        'Improve air circulation',
        'Avoid overhead watering',
        'Maintain balanced nutrition',
        'Sanitize pruning tools',
      ],
      'Grape___healthy': [
        'Continue regular pruning schedule',
        'Apply balanced vine fertilizer',
        'Monitor for pests and diseases',
        'Ensure proper trellising',
        'Water deeply but infrequently',
        'Thin fruit clusters for quality',
      ],
    };
    
    // Return specific treatments or generic ones
    return treatments[label] ?? [
      'Remove affected plant parts immediately',
      'Apply appropriate fungicide or pesticide',
      'Improve air circulation around plants',
      'Avoid overhead watering',
      'Sanitize gardening tools',
      'Consult with a local agricultural expert',
    ];
  }

  /// Dispose of resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
    print('🗑️ Disease detection model disposed');
  }
}
