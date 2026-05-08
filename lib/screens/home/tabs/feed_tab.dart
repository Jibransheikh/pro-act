import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FEED', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text('The circle is watching.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}