import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SectionMetadataEditor extends StatefulWidget {
  final String? initialMetadata;
  final Function(String) onMetadataChanged;

  const SectionMetadataEditor({
    super.key,
    this.initialMetadata,
    required this.onMetadataChanged,
  });

  @override
  State<SectionMetadataEditor> createState() => _SectionMetadataEditorState();
}

class _SectionMetadataEditorState extends State<SectionMetadataEditor> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isValidJson = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMetadata != null) {
      try {
        final formatted = const JsonEncoder.withIndent('  ')
            .convert(json.decode(widget.initialMetadata!));
        _jsonController.text = formatted;
      } catch (e) {
        _jsonController.text = widget.initialMetadata!;
      }
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'البيانات الإضافية (Metadata)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  CupertinoIcons.chevron_down,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? 300 : 0,
          child: _isExpanded ? _buildEditor() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.5),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isValidJson
              ? AppTheme.darkBorder.withValues(alpha: 0.3)
              : AppTheme.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'JSON Editor',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                _buildFormatButton(),
                const SizedBox(width: 8),
                _buildValidateButton(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                TextField(
                  controller: _jsonController,
                  maxLines: null,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: '{\n  "key": "value"\n}',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      fontFamily: 'monospace',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: _validateAndUpdate,
                ),
                if (!_isValidJson)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            size: 12,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'صيغة JSON غير صحيحة',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.error,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton() {
    return GestureDetector(
      onTap: _formatJson,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.wand_stars,
              size: 10,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 4),
            Text(
              'تنسيق',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isValidJson
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isValidJson
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isValidJson
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            size: 10,
            color: _isValidJson ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            _isValidJson ? 'صالح' : 'خطأ',
            style: AppTextStyles.caption.copyWith(
              color: _isValidJson ? AppTheme.success : AppTheme.error,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndUpdate(String value) {
    if (value.isEmpty) {
      setState(() => _isValidJson = true);
      widget.onMetadataChanged('');
      return;
    }

    try {
      json.decode(value);
      setState(() => _isValidJson = true);
      widget.onMetadataChanged(value);
    } catch (e) {
      setState(() => _isValidJson = false);
    }
  }

  void _formatJson() {
    if (_jsonController.text.isEmpty) return;

    try {
      final decoded = json.decode(_jsonController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _jsonController.text = formatted;
      setState(() => _isValidJson = true);
      widget.onMetadataChanged(formatted);
    } catch (e) {
      setState(() => _isValidJson = false);
    }
  }
}
