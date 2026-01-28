import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../features/auth/auth.dart';

/// Mobile logout button for app bars
class MobileLogoutButton extends ConsumerWidget {
  const MobileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.isMobile) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => ref.read(authProvider.notifier).logout(),
      tooltip: 'Logout',
    );
  }
}
