# UI Redesign - Code Examples

## Color Usage

### Old Way
```dart
import 'package:pulse_app/app/theme.dart';

Container(
  color: PulseColors.accent, // #00BFFF - Electric Blue
  child: Text('Server'),
)
```

### New Way
```dart
import 'package:pulse_app/app/theme.dart';

Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        PulseColors.accent,      // #6366F1 - Indigo
        PulseColors.accentGlow,  // #8B5CF6 - Violet
      ],
    ),
  ),
  child: Text('Server'),
)
```

## Card Components

### Old Way
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Server Name'),
        Text('Status: Online'),
      ],
    ),
  ),
)
```

### New Way
```dart
import 'package:pulse_app/app/widgets/widgets.dart';

ModernCard(
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      Text(
        'Server Name',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 8),
      StatusBadge(status: 'Online'),
    ],
  ),
)
```

## Buttons

### Old Way
```dart
ElevatedButton(
  onPressed: () => addServer(),
  child: Text('Add Server'),
)
```

### New Way
```dart
// With gradient background
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        PulseColors.accent,
        PulseColors.accentGlow,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: PulseColors.accent.withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: ElevatedButton.icon(
    onPressed: () => addServer(),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    icon: Icon(Icons.add_rounded),
    label: Text('Add Server'),
  ),
)
```

## Status Indicators

### Old Way
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.2),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 6),
      Text('Online'),
    ],
  ),
)
```

### New Way
```dart
import 'package:pulse_app/app/widgets/widgets.dart';

StatusBadge(
  status: 'Online',
  icon: Icons.check_circle_rounded,
)
// Automatically applies correct color and styling
```

## Empty States

### Old Way
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.dns_outlined, size: 64),
      SizedBox(height: 16),
      Text('No servers configured'),
      SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => addServer(),
        child: Text('Add Server'),
      ),
    ],
  ),
)
```

### New Way
```dart
import 'package:pulse_app/app/widgets/widgets.dart';

EmptyState(
  icon: Icons.dns_rounded,
  title: 'No servers configured',
  subtitle: 'Add your first server to start monitoring its performance',
  actionLabel: 'Add Your First Server',
  onAction: () => addServer(),
)
// Includes animations and proper styling automatically
```

## Metric Display

### Old Way
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.memory),
            Spacer(),
            Text('Now'),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '45.2%',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('CPU Usage'),
      ],
    ),
  ),
)
```

### New Way
```dart
import 'package:pulse_app/app/widgets/widgets.dart';

MetricCard(
  title: 'CPU Usage',
  value: '45.2%',
  subtitle: 'Now',
  icon: Icons.memory_rounded,
  color: PulseColors.accent,
  onTap: () => viewDetails(),
)
// Includes icon background, proper spacing, and interactions
```

## Navigation

### Old Way
```dart
NavigationRail(
  selectedIndex: 0,
  destinations: [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: Text('Dashboard'),
    ),
  ],
)
```

### New Way
```dart
// Custom sidebar with modern styling
Container(
  width: 280,
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border(
      right: BorderSide(
        color: theme.dividerColor.withOpacity(0.1),
      ),
    ),
  ),
  child: Column(
    children: [
      // Logo section with gradient
      Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PulseColors.accent,
                    PulseColors.accentGlow,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: PulseColors.accent.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(Icons.monitor_heart_rounded),
            ),
            SizedBox(width: 16),
            Text('Pulse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      // Navigation items with modern styling
      // ...
    ],
  ),
)
```

## Animations

### Page Entrance
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: 1.0),
  duration: Duration(milliseconds: 800),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) {
    return Transform.scale(
      scale: 0.8 + (0.2 * value),
      child: Opacity(
        opacity: value,
        child: child,
      ),
    );
  },
  child: YourWidget(),
)
```

### Button Glow Effect
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: colorScheme.primary.withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: action,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    child: Text('Action'),
  ),
)
```

## Input Fields

### Old Way
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Username',
    prefixIcon: Icon(Icons.person),
  ),
)
```

### New Way
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Username',
    hintText: 'Enter your username',
    prefixIcon: Icon(Icons.person_outline_rounded),
    // Theme handles the rest with proper borders, colors, etc.
  ),
)
// Automatically gets:
// - 12px border radius
// - Subtle border colors
// - Proper focus states
// - Gradient focus border
```

## Dialogs

### Old Way
```dart
AlertDialog(
  title: Text('Confirm'),
  content: Text('Are you sure?'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    TextButton(
      onPressed: confirm,
      child: Text('Confirm'),
    ),
  ],
)
```

### New Way
```dart
AlertDialog(
  title: Text('Confirm'),
  content: Text('Are you sure?'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    FilledButton(
      onPressed: confirm,
      child: Text('Confirm'),
    ),
  ],
)
// Automatically gets:
// - 20px border radius
// - Subtle border
// - Proper shadows
// - Gradient primary button
```

## List Items

### Old Way
```dart
ListTile(
  leading: Icon(Icons.server),
  title: Text('Server Name'),
  subtitle: Text('192.168.1.100'),
  trailing: Icon(Icons.chevron_right),
)
```

### New Way
```dart
ModernCard(
  margin: EdgeInsets.only(bottom: 12),
  padding: EdgeInsets.all(16),
  onTap: () => viewServer(),
  child: Row(
    children: [
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PulseColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.dns_rounded, color: PulseColors.accent),
      ),
      SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '192.168.1.100',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      StatusBadge(status: 'Online'),
      SizedBox(width: 12),
      Icon(Icons.chevron_right_rounded),
    ],
  ),
)
```

## Gradients

### Creating Gradient Backgrounds
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        PulseColors.accent,
        PulseColors.accentGlow,
      ],
    ),
  ),
)
```

### Gradient Text (for emphasis)
```dart
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [
      PulseColors.accent,
      PulseColors.accentGlow,
    ],
  ).createShader(bounds),
  child: Text(
    'Pulse',
    style: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
)
```

## Best Practices

1. **Use theme colors**: Always reference `theme.colorScheme` instead of hardcoding
2. **Consistent spacing**: Use multiples of 4 (4, 8, 12, 16, 20, 24, 32)
3. **Border radius**: 8px for small, 12px for medium, 16px for large, 20px for dialogs
4. **Animations**: Keep under 800ms for snappy feel
5. **Shadows**: Minimal and subtle (0.03-0.1 opacity)
6. **Gradients**: Use for primary actions only
7. **Icons**: Use rounded variants (_rounded suffix)
8. **Typography**: w600 for emphasis, w500 for body

## Migration Checklist

When updating existing pages:

- [ ] Update color references from old to new palette
- [ ] Replace Card with ModernCard
- [ ] Add StatusBadge components for status indicators
- [ ] Replace simple buttons with gradient buttons for primary actions
- [ ] Add entrance animations to page roots
- [ ] Update empty states with EmptyState component
- [ ] Add icon backgrounds to metric cards
- [ ] Update border radius to new standards
- [ ] Add subtle borders to cards
- [ ] Implement hover effects on interactive elements
