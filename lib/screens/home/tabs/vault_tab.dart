import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class VaultTab extends StatelessWidget {
  const VaultTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('VAULT', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text('Everything you\'ve earned.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}