import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Service for detecting if an image contains a plant leaf
/// Uses comprehensive color, shape, background, and region analysis
/// STRICT MODE: Requires clear single leaf on clean background
class LeafDetectionService {
  
  // ==================== THRESHOLDS ====================
  /// Minimum green ratio threshold for leaf detection (STRICT)
  static const double _minGreenRatio = 0.20; // 20% green pixels minimum
  
  /// Minimum green-dominant ratio (green > red and green > blue)
  static const double _minGreenDominantRatio = 0.15;
  
  /// Maximum allowed skin tone ratio
  static const double _maxSkinToneRatio = 0.15;
  
  /// Minimum center region green ratio (leaf should be in center)
  static const double _minCenterGreenRatio = 0.30;
  
  /// Maximum edge complexity for clean background
  static const double _maxBackgroundComplexity = 0.40;
  
  /// Minimum aspect ratio for leaf shape (width/height)
  static const double _minAspectRatio = 0.2;
  static const double _maxAspectRatio = 5.0;
  
  /// Minimum compactness (filled area / bounding box area)
  static const double _minCompactness = 0.30;
  static const double _maxCompactness = 0.95;
  
  /// Check if the image likely contains a plant leaf
  /// 
  /// Returns a LeafDetectionResult with isLeaf boolean and confidence
  /// STRICT: Checks color, shape, background, and single leaf criteria
  static Future<LeafDetectionResult> detectLeaf(Uint8List imageBytes) async {
    try {
      print('🍃 Starting STRICT leaf detection analysis...');
      
      // Decode image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Get pixel data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        print('❌ Could not get image byte data');
        return LeafDetectionResult(isLeaf: false, confidence: 0, reason: 'Could not analyze image');
      }
      
      final pixels = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;
      final totalPixels = width * height;
      
      // ==================== ANALYSIS ====================
      
      // 1. Color Analysis
      final colorResult = _analyzeColors(pixels, totalPixels);
      print('📊 Color Analysis:');
      print('   Green ratio: ${(colorResult.greenRatio * 100).toStringAsFixed(1)}%');
      print('   Green-dominant ratio: ${(colorResult.greenDominantRatio * 100).toStringAsFixed(1)}%');
      print('   Plant color ratio: ${(colorResult.plantColorRatio * 100).toStringAsFixed(1)}%');
      print('   Skin tone ratio: ${(colorResult.skinToneRatio * 100).toStringAsFixed(1)}%');
      print('   Avg saturation: ${(colorResult.avgSaturation * 100).toStringAsFixed(1)}%');
      
      // 2. Region Analysis (center vs edges)
      final regionResult = _analyzeRegions(pixels, width, height);
      print('📍 Region Analysis:');
      print('   Center green ratio: ${(regionResult.centerGreenRatio * 100).toStringAsFixed(1)}%');
      print('   Edge green ratio: ${(regionResult.edgeGreenRatio * 100).toStringAsFixed(1)}%');
      print('   Green concentration: ${(regionResult.greenConcentration * 100).toStringAsFixed(1)}%');
      
      // 3. Background Analysis
      final backgroundResult = _analyzeBackground(pixels, width, height);
      print('🖼️ Background Analysis:');
      print('   Background uniformity: ${(backgroundResult.uniformity * 100).toStringAsFixed(1)}%');
      print('   Is clean background: ${backgroundResult.isClean}');
      print('   Dominant background: ${backgroundResult.dominantColor}');
      
      // 4. Shape Analysis
      final shapeResult = _analyzeShape(pixels, width, height);
      print('📐 Shape Analysis:');
      print('   Aspect ratio: ${shapeResult.aspectRatio.toStringAsFixed(2)}');
      print('   Compactness: ${(shapeResult.compactness * 100).toStringAsFixed(1)}%');
      print('   Is leaf-like shape: ${shapeResult.isLeafShape}');
      
      // 5. Edge Analysis
      final edgeResult = _analyzeEdges(pixels, width, height);
      print('🔲 Edge Analysis:');
      print('   Edge density: ${(edgeResult.edgeDensity * 100).toStringAsFixed(1)}%');
      print('   Has leaf edges: ${edgeResult.hasLeafEdges}');
      
      // ==================== DECISION LOGIC ====================
      
      List<String> failReasons = [];
      List<String> passReasons = [];
      double confidence = 0;
      
      // Check 1: Skin tone (STRICT - reject faces/hands)
      if (colorResult.skinToneRatio > _maxSkinToneRatio) {
        failReasons.add('Contains skin/face (${(colorResult.skinToneRatio * 100).toStringAsFixed(0)}%)');
      }
      
      // Check 2: Minimum green content (STRICT)
      if (colorResult.greenRatio < _minGreenRatio && colorResult.greenDominantRatio < _minGreenDominantRatio) {
        failReasons.add('Insufficient green (${(colorResult.greenRatio * 100).toStringAsFixed(0)}%)');
      } else {
        passReasons.add('Good green content');
        confidence += 0.25;
      }
      
      // Check 3: Center concentration (leaf should be centered)
      if (regionResult.centerGreenRatio < _minCenterGreenRatio) {
        failReasons.add('No leaf in center (${(regionResult.centerGreenRatio * 100).toStringAsFixed(0)}%)');
      } else {
        passReasons.add('Leaf in center');
        confidence += 0.25;
      }
      
      // Check 4: Clean background
      if (!backgroundResult.isClean && backgroundResult.uniformity < 0.3) {
        failReasons.add('Busy/complex background');
      } else {
        passReasons.add('Clean background');
        confidence += 0.20;
      }
      
      // Check 5: Leaf-like shape
      if (!shapeResult.isLeafShape) {
        failReasons.add('Not leaf-shaped');
      } else {
        passReasons.add('Leaf-like shape');
        confidence += 0.15;
      }
      
      // Check 6: Edge patterns
      if (edgeResult.hasLeafEdges) {
        passReasons.add('Has leaf edges');
        confidence += 0.15;
      }
      
      // Check 7: Very low saturation = likely not a plant
      if (colorResult.avgSaturation < 0.10) {
        failReasons.add('Too desaturated');
      }
      
      // ==================== FINAL DECISION ====================
      
      bool isLeaf = false;
      String reason = '';
      
      // STRICT MODE: Must pass most checks
      if (failReasons.isEmpty && passReasons.length >= 3) {
        isLeaf = true;
        reason = 'Plant leaf detected: ${passReasons.join(", ")}';
        print('✅ LEAF DETECTED with confidence: ${(confidence * 100).toStringAsFixed(0)}%');
      } else if (failReasons.length <= 1 && passReasons.length >= 4 && colorResult.plantColorRatio > 0.35) {
        // Allow minor failures if other checks are strong
        isLeaf = true;
        confidence *= 0.8; // Reduce confidence
        reason = 'Likely plant leaf: ${passReasons.join(", ")}';
        print('⚠️ LIKELY LEAF with reduced confidence: ${(confidence * 100).toStringAsFixed(0)}%');
      } else {
        isLeaf = false;
        reason = failReasons.isNotEmpty 
            ? 'Not a leaf: ${failReasons.join(", ")}' 
            : 'Image does not appear to contain a clear leaf';
        confidence = colorResult.plantColorRatio;
        print('❌ NOT A LEAF: ${failReasons.join(", ")}');
      }
      
      return LeafDetectionResult(
        isLeaf: isLeaf,
        confidence: confidence,
        reason: reason,
        greenRatio: colorResult.greenRatio,
        plantColorRatio: colorResult.plantColorRatio,
        skinToneRatio: colorResult.skinToneRatio,
        centerGreenRatio: regionResult.centerGreenRatio,
        backgroundUniformity: backgroundResult.uniformity,
        shapeCompactness: shapeResult.compactness,
      );
      
    } catch (e) {
      print('❌ Leaf detection error: $e');
      // On error, be conservative and reject
      return LeafDetectionResult(
        isLeaf: false, 
        confidence: 0, 
        reason: 'Could not verify image. Please upload a clear leaf photo.'
      );
    }
  }
  
  /// Analyze color distribution in the image
  static _ColorAnalysisResult _analyzeColors(Uint8List pixels, int totalPixels) {
    int greenPixels = 0;
    int greenDominantPixels = 0;
    int brownPixels = 0;
    int yellowGreenPixels = 0;
    int skinTonePixels = 0;
    int whitePixels = 0;
    int blackPixels = 0;
    
    double totalSaturation = 0;
    double totalBrightness = 0;
    
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      
      final hsv = _rgbToHsv(r, g, b);
      final hue = hsv[0];
      final saturation = hsv[1];
      final value = hsv[2];
      
      totalSaturation += saturation;
      totalBrightness += value;
      
      // Green/plant colors (hue 60-180 degrees, good saturation)
      if (hue >= 60 && hue <= 180 && saturation > 0.20 && value > 0.15) {
        greenPixels++;
      }
      
      // Green-dominant pixels
      if (g > r + 10 && g > b + 10 && g > 60) {
        greenDominantPixels++;
      }
      
      // Yellow-green (diseased leaves)
      if (hue >= 40 && hue <= 90 && saturation > 0.25 && value > 0.3) {
        yellowGreenPixels++;
      }
      
      // Brown (dead tissue)
      if (hue >= 15 && hue <= 50 && saturation > 0.2 && saturation < 0.6 && value > 0.2 && value < 0.7) {
        brownPixels++;
      }
      
      // Skin tones
      if (_isSkinTone(r, g, b)) {
        skinTonePixels++;
      }
      
      // White (background)
      if (value > 0.9 && saturation < 0.1) {
        whitePixels++;
      }
      
      // Black (background)
      if (value < 0.1) {
        blackPixels++;
      }
    }
    
    final greenRatio = greenPixels / totalPixels;
    final greenDominantRatio = greenDominantPixels / totalPixels;
    final yellowGreenRatio = yellowGreenPixels / totalPixels;
    final brownRatio = brownPixels / totalPixels;
    final skinToneRatio = skinTonePixels / totalPixels;
    final plantColorRatio = greenRatio + yellowGreenRatio * 0.7 + brownRatio * 0.4;
    
    return _ColorAnalysisResult(
      greenRatio: greenRatio,
      greenDominantRatio: greenDominantRatio,
      yellowGreenRatio: yellowGreenRatio,
      brownRatio: brownRatio,
      skinToneRatio: skinToneRatio,
      plantColorRatio: plantColorRatio,
      avgSaturation: totalSaturation / totalPixels,
      avgBrightness: totalBrightness / totalPixels,
      whiteRatio: whitePixels / totalPixels,
      blackRatio: blackPixels / totalPixels,
    );
  }
  
  /// Analyze green distribution in center vs edges
  static _RegionAnalysisResult _analyzeRegions(Uint8List pixels, int width, int height) {
    int centerGreen = 0;
    int centerTotal = 0;
    int edgeGreen = 0;
    int edgeTotal = 0;
    
    // Define center region (middle 50%)
    final centerLeft = (width * 0.25).round();
    final centerRight = (width * 0.75).round();
    final centerTop = (height * 0.25).round();
    final centerBottom = (height * 0.75).round();
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if (i + 3 >= pixels.length) continue;
        
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        
        final isGreen = g > r + 5 && g > b + 5 && g > 50;
        
        // Check if in center region
        if (x >= centerLeft && x < centerRight && y >= centerTop && y < centerBottom) {
          centerTotal++;
          if (isGreen) centerGreen++;
        } else {
          edgeTotal++;
          if (isGreen) edgeGreen++;
        }
      }
    }
    
    final centerGreenRatio = centerTotal > 0 ? centerGreen / centerTotal : 0.0;
    final edgeGreenRatio = edgeTotal > 0 ? edgeGreen / edgeTotal : 0.0;
    
    // Green concentration: how much more green is in center vs edges
    final greenConcentration = edgeGreenRatio > 0 
        ? centerGreenRatio / (centerGreenRatio + edgeGreenRatio) 
        : (centerGreenRatio > 0 ? 1.0 : 0.0);
    
    return _RegionAnalysisResult(
      centerGreenRatio: centerGreenRatio,
      edgeGreenRatio: edgeGreenRatio,
      greenConcentration: greenConcentration,
    );
  }
  
  /// Analyze background (corners and edges)
  static _BackgroundAnalysisResult _analyzeBackground(Uint8List pixels, int width, int height) {
    // Sample corners to detect background color
    List<List<int>> cornerColors = [];
    final cornerSize = math.min(width, height) ~/ 8;
    
    // Sample 4 corners
    final corners = [
      [0, 0], // top-left
      [width - cornerSize, 0], // top-right
      [0, height - cornerSize], // bottom-left
      [width - cornerSize, height - cornerSize], // bottom-right
    ];
    
    int totalR = 0, totalG = 0, totalB = 0;
    int sampleCount = 0;
    
    List<double> cornerVariances = [];
    
    for (final corner in corners) {
      int cornerR = 0, cornerG = 0, cornerB = 0;
      int cornerCount = 0;
      List<int> rValues = [], gValues = [], bValues = [];
      
      for (int dy = 0; dy < cornerSize; dy++) {
        for (int dx = 0; dx < cornerSize; dx++) {
          final x = corner[0] + dx;
          final y = corner[1] + dy;
          if (x >= width || y >= height) continue;
          
          final i = (y * width + x) * 4;
          if (i + 3 >= pixels.length) continue;
          
          final r = pixels[i];
          final g = pixels[i + 1];
          final b = pixels[i + 2];
          
          cornerR += r;
          cornerG += g;
          cornerB += b;
          cornerCount++;
          
          rValues.add(r);
          gValues.add(g);
          bValues.add(b);
        }
      }
      
      if (cornerCount > 0) {
        totalR += cornerR ~/ cornerCount;
        totalG += cornerG ~/ cornerCount;
        totalB += cornerB ~/ cornerCount;
        sampleCount++;
        
        // Calculate variance in this corner
        final avgR = cornerR / cornerCount;
        final avgG = cornerG / cornerCount;
        final avgB = cornerB / cornerCount;
        
        double variance = 0;
        for (int j = 0; j < rValues.length; j++) {
          variance += (rValues[j] - avgR).abs() + (gValues[j] - avgG).abs() + (bValues[j] - avgB).abs();
        }
        cornerVariances.add(variance / (cornerCount * 3 * 255));
      }
    }
    
    // Calculate uniformity (low variance = clean background)
    final avgVariance = cornerVariances.isNotEmpty 
        ? cornerVariances.reduce((a, b) => a + b) / cornerVariances.length 
        : 1.0;
    final uniformity = 1.0 - math.min(1.0, avgVariance * 5);
    
    // Determine dominant background color
    String dominantColor = 'mixed';
    if (sampleCount > 0) {
      final avgR = totalR ~/ sampleCount;
      final avgG = totalG ~/ sampleCount;
      final avgB = totalB ~/ sampleCount;
      
      final hsv = _rgbToHsv(avgR, avgG, avgB);
      if (hsv[2] > 0.9 && hsv[1] < 0.1) {
        dominantColor = 'white';
      } else if (hsv[2] < 0.15) {
        dominantColor = 'black';
      } else if (hsv[1] < 0.15) {
        dominantColor = 'gray';
      } else if (avgG > avgR && avgG > avgB) {
        dominantColor = 'green';
      }
    }
    
    // Background is clean if uniform and not green
    final isClean = uniformity > 0.5 && dominantColor != 'green';
    
    return _BackgroundAnalysisResult(
      uniformity: uniformity,
      isClean: isClean,
      dominantColor: dominantColor,
    );
  }
  
  /// Analyze shape characteristics of green regions
  static _ShapeAnalysisResult _analyzeShape(Uint8List pixels, int width, int height) {
    int minX = width, maxX = 0;
    int minY = height, maxY = 0;
    int greenCount = 0;
    
    // Find bounding box of green pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if (i + 3 >= pixels.length) continue;
        
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        
        if (g > r && g > b && g > 50) {
          greenCount++;
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    
    if (greenCount == 0 || maxX <= minX || maxY <= minY) {
      return _ShapeAnalysisResult(aspectRatio: 0, compactness: 0, isLeafShape: false);
    }
    
    final boundingWidth = maxX - minX + 1;
    final boundingHeight = maxY - minY + 1;
    final boundingArea = boundingWidth * boundingHeight;
    
    final aspectRatio = boundingWidth / boundingHeight;
    final compactness = greenCount / boundingArea;
    
    // Leaf-like shapes have moderate aspect ratio and compactness
    final isLeafShape = aspectRatio >= _minAspectRatio && 
                        aspectRatio <= _maxAspectRatio && 
                        compactness >= _minCompactness && 
                        compactness <= _maxCompactness;
    
    return _ShapeAnalysisResult(
      aspectRatio: aspectRatio,
      compactness: compactness,
      isLeafShape: isLeafShape,
    );
  }
  
  /// Analyze edges using Sobel-like filter
  static _EdgeAnalysisResult _analyzeEdges(Uint8List pixels, int width, int height) {
    int edgeCount = 0;
    int greenEdgeCount = 0;
    final totalPixels = (width - 2) * (height - 2);
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final i = (y * width + x) * 4;
        if (i + 3 >= pixels.length) continue;
        
        // Get current pixel and neighbors for gradient
        final current = _getGrayValue(pixels, i);
        final left = _getGrayValue(pixels, ((y) * width + (x - 1)) * 4);
        final right = _getGrayValue(pixels, ((y) * width + (x + 1)) * 4);
        final top = _getGrayValue(pixels, ((y - 1) * width + x) * 4);
        final bottom = _getGrayValue(pixels, ((y + 1) * width + x) * 4);
        
        // Simple gradient magnitude
        final gx = (right - left).abs();
        final gy = (bottom - top).abs();
        final gradient = math.sqrt(gx * gx + gy * gy);
        
        if (gradient > 30) { // Edge threshold
          edgeCount++;
          
          // Check if this is a green edge
          final g = pixels[i + 1];
          final r = pixels[i];
          final b = pixels[i + 2];
          if (g > r && g > b) {
            greenEdgeCount++;
          }
        }
      }
    }
    
    final edgeDensity = totalPixels > 0 ? edgeCount / totalPixels : 0.0;
    final greenEdgeRatio = edgeCount > 0 ? greenEdgeCount / edgeCount : 0.0;
    
    // Leaf edges: moderate edge density with significant green edges
    final hasLeafEdges = edgeDensity > 0.05 && edgeDensity < 0.5 && greenEdgeRatio > 0.2;
    
    return _EdgeAnalysisResult(
      edgeDensity: edgeDensity,
      greenEdgeRatio: greenEdgeRatio,
      hasLeafEdges: hasLeafEdges,
    );
  }
  
  static double _getGrayValue(Uint8List pixels, int i) {
    if (i + 2 >= pixels.length) return 0;
    return (pixels[i] * 0.299 + pixels[i + 1] * 0.587 + pixels[i + 2] * 0.114);
  }
  
  /// Convert RGB to HSV color space
  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;
    
    final maxC = math.max(rf, math.max(gf, bf));
    final minC = math.min(rf, math.min(gf, bf));
    final delta = maxC - minC;
    
    double h = 0;
    double s = 0;
    double v = maxC;
    
    if (delta > 0) {
      s = delta / maxC;
      
      if (maxC == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (maxC == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
      
      if (h < 0) h += 360;
    }
    
    return [h, s, v];
  }
  
  /// Check if a pixel is likely skin tone
  static bool _isSkinTone(int r, int g, int b) {
    // Rule 1: RGB ratio based (covers most skin tones)
    if (r > 95 && g > 40 && b > 20 &&
        r > g && r > b &&
        (r - g).abs() > 15 &&
        r - b > 15) {
      return true;
    }
    
    // Rule 2: YCbCr color space skin detection
    final y = 0.299 * r + 0.587 * g + 0.114 * b;
    final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
    
    if (y > 80 && cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173) {
      return true;
    }
    
    // Rule 3: HSV based
    final hsv = _rgbToHsv(r, g, b);
    if (hsv[0] >= 0 && hsv[0] <= 50 && hsv[1] >= 0.15 && hsv[1] <= 0.6 && hsv[2] >= 0.2) {
      if (r > 70 && g > 40 && b > 20 && r > b) {
        return true;
      }
    }
    
    return false;
  }
}

// ==================== RESULT CLASSES ====================

class _ColorAnalysisResult {
  final double greenRatio;
  final double greenDominantRatio;
  final double yellowGreenRatio;
  final double brownRatio;
  final double skinToneRatio;
  final double plantColorRatio;
  final double avgSaturation;
  final double avgBrightness;
  final double whiteRatio;
  final double blackRatio;
  
  _ColorAnalysisResult({
    required this.greenRatio,
    required this.greenDominantRatio,
    required this.yellowGreenRatio,
    required this.brownRatio,
    required this.skinToneRatio,
    required this.plantColorRatio,
    required this.avgSaturation,
    required this.avgBrightness,
    required this.whiteRatio,
    required this.blackRatio,
  });
}

class _RegionAnalysisResult {
  final double centerGreenRatio;
  final double edgeGreenRatio;
  final double greenConcentration;
  
  _RegionAnalysisResult({
    required this.centerGreenRatio,
    required this.edgeGreenRatio,
    required this.greenConcentration,
  });
}

class _BackgroundAnalysisResult {
  final double uniformity;
  final bool isClean;
  final String dominantColor;
  
  _BackgroundAnalysisResult({
    required this.uniformity,
    required this.isClean,
    required this.dominantColor,
  });
}

class _ShapeAnalysisResult {
  final double aspectRatio;
  final double compactness;
  final bool isLeafShape;
  
  _ShapeAnalysisResult({
    required this.aspectRatio,
    required this.compactness,
    required this.isLeafShape,
  });
}

class _EdgeAnalysisResult {
  final double edgeDensity;
  final double greenEdgeRatio;
  final bool hasLeafEdges;
  
  _EdgeAnalysisResult({
    required this.edgeDensity,
    required this.greenEdgeRatio,
    required this.hasLeafEdges,
  });
}

/// Result of leaf detection analysis
class LeafDetectionResult {
  final bool isLeaf;
  final double confidence;
  final String reason;
  final double? greenRatio;
  final double? plantColorRatio;
  final double? skinToneRatio;
  final double? centerGreenRatio;
  final double? backgroundUniformity;
  final double? shapeCompactness;
  
  LeafDetectionResult({
    required this.isLeaf,
    required this.confidence,
    required this.reason,
    this.greenRatio,
    this.plantColorRatio,
    this.skinToneRatio,
    this.centerGreenRatio,
    this.backgroundUniformity,
    this.shapeCompactness,
  });
  
  @override
  String toString() {
    return 'LeafDetectionResult(isLeaf: $isLeaf, confidence: ${(confidence * 100).toStringAsFixed(1)}%, reason: $reason)';
  }
}
