import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../models/models.dart';
import '../providers/providers.dart';

/// Server list page showing all servers with status
class ServerListPage extends ConsumerWidget {
  const ServerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversState = ref.watch(serversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(serversProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(context, ref),
            tooltip: 'Add Server',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchField(),
          ),
        ),
      ),
      body: switch (serversState) {
        ServersLoading() => const _ServerListSkeleton(),
        ServersError(message: final msg) => _ServerListError(
            message: msg,
            onRetry: () => ref.read(serversProvider.notifier).refresh(),
          ),
        ServersLoaded() => const _FilteredServerListView(),
      },
    );
  }

  void _showAddServerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddServerDialog(),
    );
  }
}

/// Search field widget
class _SearchField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(serverFilterQueryProvider);

    return TextField(
      decoration: InputDecoration(
        hintText: 'Filter by name, hostname, tag, or status...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () =>
                    ref.read(serverFilterQueryProvider.notifier).state = '',
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) =>
          ref.read(serverFilterQueryProvider.notifier).state = value,
    );
  }
}

/// Filtered server list view
class _FilteredServerListView extends ConsumerWidget {
  const _FilteredServerListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(filteredServersProvider);
    final query = ref.watch(serverFilterQueryProvider);

    if (servers.isEmpty && query.isEmpty) {
      return const _EmptyServerList();
    }

    if (servers.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No servers match "$query"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(serverFilterQueryProvider.notifier).state = '',
              child: const Text('Clear filter'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(serversProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ServerCard(server: servers[index]),
          );
        },
      ),
    );
  }
}

/// Server card widget
class _ServerCard extends ConsumerWidget {
  final ServerWithMetrics server;

  const _ServerCard({required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(server.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(selectedServerIdProvider.notifier).state = server.id;
          context.go('/servers/${server.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Container(
              height: 4,
              color: statusColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      _StatusIndicator(status: server.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${server.hostname}:${server.port}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(context, ref, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'connect',
                            child: Row(
                              children: [
                                Icon(Icons.terminal, size: 20),
                                SizedBox(width: 8),
                                Text('Connect'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
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
                  const SizedBox(height: 16),
                  // Metrics row
                  if (server.isOnline) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.memory,
                            label: 'CPU',
                            value: server.cpuPercent != null
                                ? '${server.cpuPercent!.toStringAsFixed(1)}%'
                                : '--',
                            color: _getMetricColor(server.cpuPercent),
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.storage,
                            label: 'Memory',
                            value: server.memoryPercent != null
                                ? '${server.memoryPercent!.toStringAsFixed(1)}%'
                                : '--',
                            color: _getMetricColor(server.memoryPercent),
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.disc_full,
                            label: 'Disk',
                            value: server.diskPercent != null
                                ? '${server.diskPercent!.toStringAsFixed(1)}%'
                                : '--',
                            color: _getMetricColor(server.diskPercent),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      server.lastSeenAt != null
                          ? 'Last seen: ${_formatLastSeen(server.lastSeenAt!)}'
                          : 'Never connected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // Tags
                  if (server.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: server.tags.map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: theme.textTheme.labelSmall,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
      case ServerStatus.warning:
        return Colors.orange;
      case ServerStatus.unknown:
        return Colors.grey;
    }
  }

  Color _getMetricColor(double? value) {
    if (value == null) return Colors.grey;
    if (value >= 90) return Colors.red;
    if (value >= 70) return Colors.orange;
    return Colors.green;
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSeen.month}/${lastSeen.day}/${lastSeen.year}';
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'connect':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('SSH Terminal'),
            content: const Text(
              'SSH terminal access is a planned feature that will allow you '
              'to connect directly to your server from the browser.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
      case 'edit':
        showDialog(
          context: context,
          builder: (ctx) => _EditServerDialog(server: server),
        );
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text('Are you sure you want to delete "${server.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(serversProvider.notifier).deleteServer(server.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Status indicator dot
class _StatusIndicator extends StatelessWidget {
  final ServerStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIcon(),
        color: _getColor(),
        size: 20,
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
      case ServerStatus.warning:
        return Colors.orange;
      case ServerStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case ServerStatus.online:
        return Icons.check_circle;
      case ServerStatus.offline:
        return Icons.cancel;
      case ServerStatus.warning:
        return Icons.warning;
      case ServerStatus.unknown:
        return Icons.help_outline;
    }
  }
}

/// Metric tile widget
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading state
class _ServerListSkeleton extends StatelessWidget {
  const _ServerListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Error state
class _ServerListError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ServerListError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load servers',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state
class _EmptyServerList extends StatelessWidget {
  const _EmptyServerList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No servers yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first server to start monitoring',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const _AddServerDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Server'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add server dialog
class _AddServerDialog extends ConsumerStatefulWidget {
  const _AddServerDialog();

  @override
  ConsumerState<_AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends ConsumerState<_AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Server'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Server',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostnameController,
                decoration: const InputDecoration(
                  labelText: 'Hostname / IP',
                  hintText: '192.168.1.100',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a hostname or IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'SSH Port',
                  hintText: '22',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Please enter a valid port (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Web server in living room',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  hintText: 'production, web, docker',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse tags from comma-separated string
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty
          ? <String>[]
          : tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final request = CreateServerRequest(
        name: _nameController.text.trim(),
        hostname: _hostnameController.text.trim(),
        port: int.parse(_portController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: tags.isEmpty ? null : tags,
      );

      await ref.read(serversProvider.notifier).createServer(request);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add server: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Edit server dialog
class _EditServerDialog extends ConsumerStatefulWidget {
  final ServerWithMetrics server;

  const _EditServerDialog({required this.server});

  @override
  ConsumerState<_EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends ConsumerState<_EditServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostnameController;
  late final TextEditingController _portController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server.name);
    _hostnameController = TextEditingController(text: widget.server.hostname);
    _portController = TextEditingController(text: widget.server.port.toString());
    _descriptionController = TextEditingController(text: widget.server.description ?? '');
    _tagsController = TextEditingController(text: widget.server.tags.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Server'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Server',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostnameController,
                decoration: const InputDecoration(
                  labelText: 'Hostname / IP',
                  hintText: '192.168.1.100',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a hostname or IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'SSH Port',
                  hintText: '22',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Please enter a valid port (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Web server in living room',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  hintText: 'production, web, docker',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse tags from comma-separated string
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty
          ? <String>[]
          : tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final request = UpdateServerRequest(
        name: _nameController.text.trim(),
        hostname: _hostnameController.text.trim(),
        port: int.parse(_portController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: tags,
      );

      await ref.read(serversProvider.notifier).updateServer(widget.server.id, request);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update server: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
