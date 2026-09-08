import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';

void main() {
  test('AppTheme darkTheme configuration sanity test', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, equals(Brightness.dark));
    expect(theme.scaffoldBackgroundColor, equals(AppTheme.background));
    expect(theme.primaryColor, equals(AppTheme.primary));
  });
}
