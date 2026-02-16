import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/custom_appbar.dart';

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  String? _selectedPlantType;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Plant Health Analysis',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analyze Plant Health',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload or capture an image of your plant to analyze its health status',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: textGray,
                    ),
              ),
              const SizedBox(height: 32),

              // Image Upload Section
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: primaryGreen, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: lightGreen,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to upload plant image',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or take a photo directly',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Source Options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined),
                          SizedBox(width: 8),
                          Text('Camera'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined),
                          SizedBox(width: 8),
                          Text('Gallery'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Plant Type Selection
              Text(
                'Select Plant Type (Optional)',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Tomato',
                  'Rose',
                  'Basil',
                  'Lettuce',
                  'Pepper',
                  'Other',
                ]
                    .map((type) => FilterChip(
                          label: Text(type),
                          selected: _selectedPlantType == type,
                          onSelected: (selected) {
                            setState(() => _selectedPlantType =
                                selected ? type : null);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 40),

              // Analysis Result (Mock)
              if (_isAnalyzing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Results',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: successGreen),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: successGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plant is Healthy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: successGreen,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No diseases detected',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: textGray),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recommendations',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Water regularly every 2-3 days\n• Ensure 6-8 hours of sunlight\n• Apply balanced fertilizer monthly',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 50,
                        color: textGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload an image to see analysis results',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: textGray),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isAnalyzing = !_isAnalyzing);
                  },
                  child: const Text('Analyze Plant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
