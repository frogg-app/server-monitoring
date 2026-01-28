import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/widgets/widgets.dart';
import '../../auth/auth.dart';
import '../../alerts/alerts.dart';
import '../providers/providers.dart';

/// Settings page with user profile and notification settings
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          MobileLogoutButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User section
          if (authState is AuthAuthenticated) ...[
            _SectionHeader(title: 'Account'),
            const SizedBox(height: 8),
            _UserCard(user: authState.user),
            const SizedBox(height: 24),
          ],

          // Notification channels section
          _SectionHeader(
            title: 'Notification Channels',
            action: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddChannelDialog(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          const _NotificationChannelsList(),
          const SizedBox(height: 24),

          // Key Management section
          _SectionHeader(
            title: 'SSH Key Management',
            action: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showGenerateKeyDialog(context, ref),
              tooltip: 'Generate new SSH key',
            ),
          ),
          const SizedBox(height: 8),
          const _SSHKeysList(),
          const SizedBox(height: 24),

          // Appearance section
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isDark = themeMode == ThemeMode.dark;
                    return ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).state =
                              value ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  trailing: Text(
                    '1.0.0-alpha',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Documentation'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    // Open docs page in new tab
                    _launchDocs(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger zone
          _SectionHeader(title: 'Session'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddNotificationChannelDialog(),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _launchDocs(BuildContext context) async {
    // Open the documentation page
    final uri = Uri.parse('/docs/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documentation available at /docs/')),
        );
      }
    }
  }

  void _showGenerateKeyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _GenerateKeyDialog(),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// User info card
class _UserCard extends StatelessWidget {
  final User user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Edit profile
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification channels list
class _NotificationChannelsList extends ConsumerWidget {
  const _NotificationChannelsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsState = ref.watch(notificationChannelsProvider);
    final theme = Theme.of(context);

    return Card(
      child: switch (channelsState) {
        NotificationChannelsLoading() => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        NotificationChannelsError(message: final msg) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(height: 8),
                Text('Error: $msg'),
              ],
            ),
          ),
        NotificationChannelsLoaded(channels: final channels) =>
          channels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No notification channels configured',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: channels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final channel = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const Divider(height: 1),
                        _NotificationChannelTile(channel: channel),
                      ],
                    );
                  }).toList(),
                ),
      },
    );
  }
}

/// Notification channel tile
class _NotificationChannelTile extends ConsumerWidget {
  final NotificationChannel channel;

  const _NotificationChannelTile({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(_getIcon(channel.type)),
      title: Text(channel.name),
      subtitle: Text(
        channel.type.name.toUpperCase(),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            tooltip: 'Test',
            onPressed: () async {
              final success = await ref
                  .read(notificationChannelsProvider.notifier)
                  .testChannel(channel.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Test notification sent!'
                          : 'Test notification failed',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
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
    );
  }

  IconData _getIcon(NotificationChannelType type) {
    switch (type) {
      case NotificationChannelType.email:
        return Icons.email;
      case NotificationChannelType.webhook:
        return Icons.webhook;
      case NotificationChannelType.slack:
        return Icons.message;
      case NotificationChannelType.discord:
        return Icons.discord;
      case NotificationChannelType.telegram:
        return Icons.telegram;
      case NotificationChannelType.pushover:
        return Icons.notifications;
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Channel'),
          content: Text('Are you sure you want to delete "${channel.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(notificationChannelsProvider.notifier)
                    .deleteChannel(channel.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }
}

/// SSH Keys list widget
class _SSHKeysList extends ConsumerWidget {
  const _SSHKeysList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(keysListProvider);
    final theme = Theme.of(context);

    return Card(
      child: keysAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text('Error loading keys: $error'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(keysListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (keys) => keys.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.vpn_key_off,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No SSH keys generated yet',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a key to connect to servers securely',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: keys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final key = entry.value;
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 1),
                      _SSHKeyTile(sshKey: key),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}

/// SSH Key tile widget
class _SSHKeyTile extends ConsumerWidget {
  final SSHKey sshKey;

  const _SSHKeyTile({required this.sshKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: Text(sshKey.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sshKey.keyType.toUpperCase()} • ${sshKey.fingerprint}',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Created ${_formatDate(sshKey.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(context, ref, value),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy Public Key'),
              ],
            ),
          ),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: sshKey.publicKey));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Public key copied to clipboard')),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete SSH Key'),
            content: Text('Are you sure you want to delete "${sshKey.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final keyService = ref.read(keyServiceProvider);
                    await keyService.deleteKey(sshKey.id);
                    ref.invalidate(keysListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SSH key deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete key: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

/// Add notification channel dialog
class _AddNotificationChannelDialog extends ConsumerStatefulWidget {
  const _AddNotificationChannelDialog();

  @override
  ConsumerState<_AddNotificationChannelDialog> createState() =>
      _AddNotificationChannelDialogState();
}

class _AddNotificationChannelDialogState
    extends ConsumerState<_AddNotificationChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  NotificationChannelType _selectedType = NotificationChannelType.webhook;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Notification Channel'),
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
                  hintText: 'My Webhook',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NotificationChannelType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: NotificationChannelType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: _getUrlLabel(),
                  hintText: _getUrlHint(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
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

  String _getUrlLabel() {
    switch (_selectedType) {
      case NotificationChannelType.email:
        return 'Email Address';
      case NotificationChannelType.webhook:
      case NotificationChannelType.slack:
      case NotificationChannelType.discord:
        return 'Webhook URL';
      case NotificationChannelType.telegram:
        return 'Bot Token';
      case NotificationChannelType.pushover:
        return 'User Key';
    }
  }

  String _getUrlHint() {
    switch (_selectedType) {
      case NotificationChannelType.email:
        return 'user@example.com';
      case NotificationChannelType.webhook:
        return 'https://example.com/webhook';
      case NotificationChannelType.slack:
        return 'https://hooks.slack.com/...';
      case NotificationChannelType.discord:
        return 'https://discord.com/api/webhooks/...';
      case NotificationChannelType.telegram:
        return '123456:ABC-DEF...';
      case NotificationChannelType.pushover:
        return 'user_key';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = _buildConfig();
      final request = CreateNotificationChannelRequest(
        name: _nameController.text.trim(),
        type: _selectedType,
        config: config,
      );

      await ref
          .read(notificationChannelsProvider.notifier)
          .createChannel(request);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add channel: $e'),
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

  Map<String, dynamic> _buildConfig() {
    switch (_selectedType) {
      case NotificationChannelType.email:
        return {'email': _urlController.text.trim()};
      case NotificationChannelType.webhook:
      case NotificationChannelType.slack:
      case NotificationChannelType.discord:
        return {'url': _urlController.text.trim()};
      case NotificationChannelType.telegram:
        return {'bot_token': _urlController.text.trim()};
      case NotificationChannelType.pushover:
        return {'user_key': _urlController.text.trim()};
    }
  }
}

/// Generate SSH Key dialog
class _GenerateKeyDialog extends ConsumerStatefulWidget {
  const _GenerateKeyDialog();

  @override
  ConsumerState<_GenerateKeyDialog> createState() => _GenerateKeyDialogState();
}

class _GenerateKeyDialogState extends ConsumerState<_GenerateKeyDialog> {
  final _nameController = TextEditingController(text: 'Pulse Server Key');
  bool _isLoading = false;
  GeneratedKeyPair? _generatedKey;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_generatedKey != null) {
      // Show generated key
      return AlertDialog(
        title: const Text('SSH Key Generated'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Your new SSH key has been generated. '
                'Save the private key securely - it will not be shown again!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text('Public Key:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _generatedKey!.publicKey,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _copyToClipboard(
                        context, _generatedKey!.publicKey, 'Public key'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Public Key'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Private Key:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _generatedKey!.privateKey,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _copyToClipboard(
                        context, _generatedKey!.privateKey, 'Private key'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Private Key'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
    }

    // Show generation form
    return AlertDialog(
      title: const Text('Generate SSH Key'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Key Name',
                hintText: 'e.g., Pulse Server Key',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'An Ed25519 SSH key pair will be generated. '
                      'The private key will only be shown once.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _generateKey,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  Future<void> _generateKey() async {
    setState(() => _isLoading = true);

    try {
      final keyService = ref.read(keyServiceProvider);
      final key = await keyService.generateKey(
        name: _nameController.text.trim(),
        store: true, // Store the key in the backend
      );
      // Refresh the keys list
      ref.invalidate(keysListProvider);
      setState(() {
        _generatedKey = key;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate key: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }
}
