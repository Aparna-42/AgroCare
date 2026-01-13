import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/custom_appbar.dart';

class WeatherAdvisoryScreen extends StatelessWidget {
  const WeatherAdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Weather Advisory',
        onLeadingPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Weather
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryGreen, accentGreen],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Weather',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            size: 50,
                            color: white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sunny',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '28°C',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .copyWith(
                                  color: white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Temperature',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '65%',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .copyWith(
                                  color: white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Humidity',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Weather Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detailed Information',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildWeatherInfoTile(context, 'Rainfall', '2 mm', Icons.water_drop_outlined, Colors.blue),
                  const SizedBox(height: 12),
                  _buildWeatherInfoTile(context, 'Wind Speed', '12 km/h', Icons.air_outlined, Colors.grey),
                  const SizedBox(height: 12),
                  _buildWeatherInfoTile(context, 'UV Index', '6 (High)', Icons.wb_incandescent_outlined, warningOrange),
                  const SizedBox(height: 12),
                  _buildWeatherInfoTile(context, 'Pressure', '1013 mb', Icons.compress_outlined, Colors.purple),
                  const SizedBox(height: 24),

                  // Forecast
                  Text(
                    '5-Day Forecast',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => _buildForecastCard(
                          context,
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][index],
                          [Icons.wb_sunny_outlined, Icons.cloud_outlined, Icons.cloud_outlined, Icons.opacity_outlined, Icons.wb_sunny_outlined][index],
                          ['27°', '25°', '23°', '24°', '28°'][index],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Agricultural Advisory
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: warningOrange),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: warningOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Agricultural Advisory',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: warningOrange,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Rainfall expected tomorrow, prepare plants\n• Water your plants today before the rain\n• High UV index - provide shade to sensitive plants',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: textGray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: textGray,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(
    BuildContext context,
    String day,
    IconData icon,
    String temp,
  ) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textGray,
                ),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: 30, color: primaryGreen),
          const SizedBox(height: 8),
          Text(
            temp,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
