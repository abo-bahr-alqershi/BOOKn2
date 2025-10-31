// lib/features/home/presentation/widgets/sections/section_loading_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/loading_widget.dart';

class SectionLoadingWidget extends StatelessWidget {
  const SectionLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 250,
      child: Center(
        child: LoadingWidget(
          type: LoadingType.futuristic,
        ),
      ),
    );
  }
}
