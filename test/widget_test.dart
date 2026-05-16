import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:like_a_local/theme/app_colors.dart';
import 'package:like_a_local/theme/app_theme.dart';

void main() {
  testWidgets('App theme smoke test', (WidgetTester tester) async {
    // Verify theme can be created without errors
    final theme = AppTheme.lightTheme;
    expect(theme.primaryColor, AppColors.primary);
    expect(theme.useMaterial3, true);
  });

  test('AppColors are defined correctly', () {
    expect(AppColors.primary, Color(0xFF2F6E7E));
    expect(AppColors.accent, Color(0xFF7ED957));
    expect(AppColors.background, Color(0xFFF5F5F5));
    expect(AppColors.foreground, Color(0xFF030213));
  });
}
