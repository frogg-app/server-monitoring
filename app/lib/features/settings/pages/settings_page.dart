import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../../alerts/alerts.dart';

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
                  leading: const Icon(Icons.code),
                  title: const Text('Source Code'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    // TODO: Open GitHub
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Documentation'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    // TODO: Open docs
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
