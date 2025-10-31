import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Assuming you use SVG for icons
import '../theme/app_text_styles.dart';

class EmptyWidget extends StatelessWidget {
  final String message;
  final String? emptyImage; // Path to an empty state illustration (e.g., SVG or PNG)
  final Widget? actionWidget; // Optional widget for action (e.g., button to add item)

  const EmptyWidget({
    super.key,
    required this.message,
    this.emptyImage,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emptyImage != null && emptyImage!.toLowerCase().endsWith('.svg'))
              SvgPicture.asset(
                emptyImage!,
                height: 100, // Adjust size as needed
              )
            else if (emptyImage != null)
              Image.asset(
                emptyImage!,
                height: 100, // Adjust size as needed
              ),
            const SizedBox(height: 20.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
            if (actionWidget != null) ...[
              const SizedBox(height: 24.0),
              actionWidget!,
            ],
          ],
        ),
      ),
    );
  }
}