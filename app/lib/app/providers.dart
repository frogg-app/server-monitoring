import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current ThemeMode for the app (light/dark/system)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
