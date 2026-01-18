import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../repositories/server_repository.dart';
import '../../metrics/metrics.dart';
import '../../containers/containers.dart';
import '../../../core/api/api.dart';

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
        final serverState = ref.read(serverDetailProvider(serverId));
        if (serverState is ServerDetailLoaded) {
          final result = await showDialog<bool>(
            context: context,
            builder: (ctx) => EditServerDialog(
              server: serverState.server,
              onSave: (request) async {
                await ref.read(serverDetailProvider(serverId).notifier).updateServer(request);
              },
            ),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server updated successfully')),
            );
          }
        }
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
          
          // Credentials section
          _CredentialsCard(serverId: serverId),
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

/// Credentials card
class _CredentialsCard extends ConsumerWidget {
  final String serverId;

  const _CredentialsCard({required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final credsState = ref.watch(serverCredentialsProvider(serverId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credentials',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showAddCredentialDialog(context, ref),
                  tooltip: 'Add Credential',
                ),
              ],
            ),
            const SizedBox(height: 8),
            switch (credsState) {
              CredentialsLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              CredentialsError(message: final msg) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Failed to load credentials',
                            style: TextStyle(color: theme.colorScheme.error)),
                        Text(msg, style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: () => ref
                              .read(serverCredentialsProvider(serverId).notifier)
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              CredentialsLoaded(credentials: final creds) => creds.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.key_off,
                                size: 40, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'No credentials configured',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _showAddCredentialDialog(context, ref),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Credential'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: creds.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cred = creds[index];
                        return ListTile(
                          leading: Icon(
                            cred.type == CredentialType.sshKey
                                ? Icons.vpn_key
                                : Icons.password,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(cred.name),
                          subtitle: Text(
                            '${cred.type == CredentialType.sshKey ? 'SSH Key' : 'Password'} • ${cred.username ?? 'N/A'}',
                          ),
                          trailing: IconButton(
                            icon:
                                Icon(Icons.delete, color: theme.colorScheme.error),
                            onPressed: () => _confirmDelete(context, ref, cred),
                          ),
                        );
                      },
                    ),
            },
          ],
        ),
      ),
    );
  }

  void _showAddCredentialDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddCredentialDialog(serverId: serverId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Credential cred) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text('Are you sure you want to delete "${cred.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(serverCredentialsProvider(serverId).notifier)
                  .deleteCredential(cred.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Add credential dialog
class _AddCredentialDialog extends ConsumerStatefulWidget {
  final String serverId;

  const _AddCredentialDialog({required this.serverId});

  @override
  ConsumerState<_AddCredentialDialog> createState() =>
      _AddCredentialDialogState();
}

class _AddCredentialDialogState extends ConsumerState<_AddCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  CredentialType _type = CredentialType.sshPassword;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Credential'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type selector
                DropdownButtonFormField<CredentialType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Authentication Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: CredentialType.sshPassword,
                      child: Text('SSH Password'),
                    ),
                    DropdownMenuItem(
                      value: CredentialType.sshKey,
                      child: Text('SSH Key'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Credential Name',
                    hintText: 'e.g., Production SSH',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'e.g., root',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),

                // Password (for SSH Password type)
                if (_type == CredentialType.sshPassword) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password is required' : null,
                  ),
                ],

                // Private key (for SSH Key type)
                if (_type == CredentialType.sshKey) ...[
                  TextFormField(
                    controller: _privateKeyController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Private Key',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Private key is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passphraseController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase (optional)',
                    ),
                  ),
                ],
              ],
            ),
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
      final notifier =
          ref.read(serverCredentialsProvider(widget.serverId).notifier);

      if (_type == CredentialType.sshPassword) {
        final req = CreateSshPasswordCredentialRequest(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
        await notifier.createSshPassword(req);
      } else {
        final req = CreateSshKeyCredentialRequest(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          privateKey: _privateKeyController.text,
          passphrase: _passphraseController.text.isEmpty
              ? null
              : _passphraseController.text,
        );
        await notifier.createSshKey(req);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credential added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add credential: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Edit server dialog
class EditServerDialog extends StatefulWidget {
  final Server server;
  final Future<void> Function(UpdateServerRequest request) onSave;

  const EditServerDialog({
    super.key,
    required this.server,
    required this.onSave,
  });

  @override
  State<EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<EditServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostnameController;
  late final TextEditingController _portController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  bool _isLoading = false;
  String? _error;

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
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Edit Server'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'My Server',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
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
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    hintText: 'production, web, docker',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
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
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

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

      await widget.onSave(request);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to update server: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
