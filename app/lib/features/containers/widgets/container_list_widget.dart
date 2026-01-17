import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../providers/container_provider.dart';

/// Container list widget for displaying containers in a server
class ContainerListWidget extends ConsumerWidget {
  final String serverId;

  const ContainerListWidget({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containersState = ref.watch(containersProvider(serverId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Containers',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.read(containersProvider(serverId).notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            switch (containersState) {
              ContainersLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ContainersError(message: final msg) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text('Error: $msg'),
                      ],
                    ),
                  ),
                ),
              ContainersLoaded(containers: final containers) =>
                containers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No containers found'),
                        ),
                      )
                    : Column(
                        children: [
                          // Summary row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                _StatusBadge(
                                  label:
                                      '${containersState.runningCount} running',
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(
                                  label: '${containersState.totalCount} total',
                                  color: theme.colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                          // Container list
                          ...containers.map((container) => _ContainerTile(
                                serverId: serverId,
                                container: container,
                              )),
                        ],
                      ),
            },
          ],
        ),
      ),
    );
  }
}

/// Container tile widget
class _ContainerTile extends ConsumerWidget {
  final String serverId;
  final DockerContainer container;

  const _ContainerTile({
    required this.serverId,
    required this.container,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stateColor = _getStateColor(container.state);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.view_in_ar,
              color: stateColor,
              size: 20,
            ),
          ),
          title: Text(
            container.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                container.image,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StateBadge(state: container.state),
                  if (container.health != HealthStatus.none) ...[
                    const SizedBox(width: 4),
                    _HealthBadge(health: container.health),
                  ],
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<ContainerAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (context) => _buildMenuItems(),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Color _getStateColor(ContainerState state) {
    switch (state) {
      case ContainerState.running:
        return Colors.green;
      case ContainerState.paused:
        return Colors.orange;
      case ContainerState.restarting:
        return Colors.blue;
      case ContainerState.exited:
      case ContainerState.dead:
        return Colors.red;
      case ContainerState.created:
        return Colors.grey;
      case ContainerState.removing:
        return Colors.orange;
      case ContainerState.unknown:
        return Colors.grey;
    }
  }

  List<PopupMenuEntry<ContainerAction>> _buildMenuItems() {
    final items = <PopupMenuEntry<ContainerAction>>[];

    if (container.state.canStart) {
      items.add(const PopupMenuItem(
        value: ContainerAction.start,
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 20),
            SizedBox(width: 8),
            Text('Start'),
          ],
        ),
      ));
    }

    if (container.state.canStop) {
      items.add(const PopupMenuItem(
        value: ContainerAction.stop,
        child: Row(
          children: [
            Icon(Icons.stop, size: 20),
            SizedBox(width: 8),
            Text('Stop'),
          ],
        ),
      ));
    }

    if (container.state.canRestart) {
      items.add(const PopupMenuItem(
        value: ContainerAction.restart,
        child: Row(
          children: [
            Icon(Icons.refresh, size: 20),
            SizedBox(width: 8),
            Text('Restart'),
          ],
        ),
      ));
    }

    if (container.state.canPause) {
      items.add(const PopupMenuItem(
        value: ContainerAction.pause,
        child: Row(
          children: [
            Icon(Icons.pause, size: 20),
            SizedBox(width: 8),
            Text('Pause'),
          ],
        ),
      ));
    }

    if (container.state.canUnpause) {
      items.add(const PopupMenuItem(
        value: ContainerAction.unpause,
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 20),
            SizedBox(width: 8),
            Text('Unpause'),
          ],
        ),
      ));
    }

    if (items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }

    items.add(const PopupMenuItem(
      value: ContainerAction.remove,
      child: Row(
        children: [
          Icon(Icons.delete, size: 20, color: Colors.red),
          SizedBox(width: 8),
          Text('Remove', style: TextStyle(color: Colors.red)),
        ],
      ),
    ));

    return items;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ContainerAction action,
  ) async {
    try {
      if (action == ContainerAction.remove) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Container'),
            content: Text('Are you sure you want to remove "${container.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      await ref
          .read(containersProvider(serverId).notifier)
          .performAction(container.id, action);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.displayName} completed for ${container.name}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// State badge widget
class _StateBadge extends StatelessWidget {
  final ContainerState state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.name,
        style: TextStyle(
          fontSize: 10,
          color: _getColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (state) {
      case ContainerState.running:
        return Colors.green;
      case ContainerState.paused:
        return Colors.orange;
      case ContainerState.restarting:
        return Colors.blue;
      case ContainerState.exited:
      case ContainerState.dead:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Health badge widget
class _HealthBadge extends StatelessWidget {
  final HealthStatus health;

  const _HealthBadge({required this.health});

  @override
  Widget build(BuildContext context) {
    if (health == HealthStatus.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 10,
            color: _getColor(),
          ),
          const SizedBox(width: 2),
          Text(
            health.name,
            style: TextStyle(
              fontSize: 10,
              color: _getColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (health) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.starting:
        return Colors.orange;
      case HealthStatus.none:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (health) {
      case HealthStatus.healthy:
        return Icons.favorite;
      case HealthStatus.unhealthy:
        return Icons.heart_broken;
      case HealthStatus.starting:
        return Icons.hourglass_empty;
      case HealthStatus.none:
        return Icons.remove;
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
