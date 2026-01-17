import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../../metrics/metrics.dart';
import '../../containers/containers.dart';

/// Server detail page showing metrics, containers, and actions
class ServerDetailPage extends ConsumerWidget {
  final String serverId;

  const ServerDetailPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverDetailProvider(serverId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/servers'),
        ),
        title: switch (serverState) {
          ServerDetailLoading() => const Text('Loading...'),
          ServerDetailError() => const Text('Error'),
          ServerDetailLoaded(server: final s) => Text(s.name),
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(serverDetailProvider(serverId).notifier).loadServer();
              ref.read(currentMetricsProvider(serverId).notifier).refresh();
              ref.read(containersProvider(serverId).notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.terminal),
            onPressed: () {
              // SSH terminal requires backend WebSocket support
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('SSH Terminal'),
                  content: const Text(
                    'Web-based SSH terminal is planned for a future release. '
                    'For now, connect using your preferred SSH client:\n\n'
                    'ssh user@hostname -p port',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Open Terminal',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Server'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Test Connection'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: switch (serverState) {
        ServerDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        ServerDetailError(message: final msg) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load server'),
                const SizedBox(height: 8),
                Text(msg, style: theme.textTheme.bodySmall),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    ref.read(serverDetailProvider(serverId).notifier).loadServer();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ServerDetailLoaded(server: final server) => _ServerDetailContent(
            serverId: serverId,
            server: server,
          ),
      },
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        // TODO: Show edit dialog
        break;
      case 'test':
        final success = await ref
            .read(serverDetailProvider(serverId).notifier)
            .testConnection();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Connection successful!' : 'Connection failed',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Server'),
            content: const Text(
              'Are you sure you want to delete this server? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          // Delete and navigate back
          context.go('/servers');
        }
        break;
    }
  }
}

/// Server detail content
class _ServerDetailContent extends StatelessWidget {
  final String serverId;
  final dynamic server;

  const _ServerDetailContent({
    required this.serverId,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Server info card
          _ServerInfoCard(server: server),
          const SizedBox(height: 16),
          
          // Current metrics
          CurrentMetricsCard(serverId: serverId),
          const SizedBox(height: 16),
          
          // Time range selector for charts
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TimeRangeSelector(),
          ),
          const SizedBox(height: 16),
          
          // Containers
          ContainerListWidget(serverId: serverId),
        ],
      ),
    );
  }
}

/// Server info card
class _ServerInfoCard extends StatelessWidget {
  final dynamic server;

  const _ServerInfoCard({required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(server.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dns,
                    color: _getStatusColor(server.status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${server.hostname}:${server.port}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: server.status),
              ],
            ),
            if (server.description != null && server.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                server.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (server.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: server.tags
                    .map<Widget>((tag) => Chip(
                          label: Text(tag),
                          labelStyle: theme.textTheme.labelSmall,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusName = status.toString().split('.').last;
    switch (statusName) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Status chip
class _StatusChip extends StatelessWidget {
  final dynamic status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusName = status.toString().split('.').last;
    final color = _getColor(statusName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _capitalize(statusName),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String statusName) {
    switch (statusName) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
