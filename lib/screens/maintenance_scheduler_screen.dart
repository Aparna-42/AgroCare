import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/custom_appbar.dart';

class MaintenanceSchedulerScreen extends StatefulWidget {
  const MaintenanceSchedulerScreen({super.key});

  @override
  State<MaintenanceSchedulerScreen> createState() =>
      _MaintenanceSchedulerScreenState();
}

class _MaintenanceSchedulerScreenState extends State<MaintenanceSchedulerScreen> {
  String _filterType = 'all'; // all, completed, pending

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Maintenance Schedule',
        onLeadingPressed: () => context.pop(),
      ),
      body: Consumer<MaintenanceProvider>(
        builder: (context, maintenanceProvider, _) {
          final tasks = _filterType == 'completed'
              ? maintenanceProvider.tasks.where((t) => t.isCompleted).toList()
              : _filterType == 'pending'
                  ? maintenanceProvider.pendingTasks
                  : maintenanceProvider.tasks;

          return Column(
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8,
                  children: ['all', 'pending', 'completed']
                      .map((type) => FilterChip(
                            label: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
                            selected: _filterType == type,
                            onSelected: (selected) {
                              setState(() => _filterType = type);
                            },
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 60,
                              color: textGray.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No $_filterType tasks',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: textGray),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildTaskCard(context, task, maintenanceProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    dynamic task,
    MaintenanceProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isCompleted ? lightGray : white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted ? lightGray : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              provider.completeTask(task.id);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskType.toString().toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted ? textGray : primaryGreen,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: textGray),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: textGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${task.scheduledDate.day}/${task.scheduledDate.month}/${task.scheduledDate.year}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: textGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Text('Delete'),
                onTap: () {
                  provider.removeTask(task.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
