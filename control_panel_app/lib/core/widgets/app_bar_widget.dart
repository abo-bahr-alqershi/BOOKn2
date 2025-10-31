import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemUiOverlayStyle

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double? elevation;
  final Widget? leadingWidget; // Custom leading widget

  const AppBarWidget({
    super.key,
    required this.title,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.backgroundColor,
    this.systemOverlayStyle,
    this.elevation,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the correct status bar icons based on background color
    final currentSystemOverlayStyle = systemOverlayStyle ??
        (backgroundColor == null || backgroundColor!.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light);
            
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      elevation: elevation,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leadingWidget ?? (automaticallyImplyLeading ? null : const SizedBox.shrink()), // Use custom leading or default behavior
      
      // Customize title text style if needed, or rely on theme
      // titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle, 
      
      // Set system UI overlay style for the status bar
      systemOverlayStyle: currentSystemOverlayStyle.copyWith(
         statusBarColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}