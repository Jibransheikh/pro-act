import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CircleTab extends StatelessWidget {
  const CircleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CIRCLE', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text('Your people. Your witnesses.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}