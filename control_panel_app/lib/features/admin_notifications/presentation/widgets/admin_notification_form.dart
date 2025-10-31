// lib/features/admin_notifications/presentation/widgets/admin_notification_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../helpers/presentation/utils/search_navigation_helper.dart';
import '../../../admin_users/domain/entities/user.dart';
import '../../../notification_channels/domain/entities/notification_channel.dart';
import '../../../notification_channels/data/datasources/notification_channels_remote_datasource.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class AdminNotificationForm extends StatefulWidget {
  final bool isBroadcast;
  final Function(Map<String, dynamic>) onSubmit;

  const AdminNotificationForm({
    super.key,
    required this.isBroadcast,
    required this.onSubmit,
  });

  @override
  State<AdminNotificationForm> createState() => _AdminNotificationFormState();
}

class _AdminNotificationFormState extends State<AdminNotificationForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  User? _selectedRecipient;
  final List<User> _selectedUsers = [];

  String _selectedType = 'booking';
  String _selectedPriority = 'normal';
  bool _targetAll = false;
  final List<String> _selectedRoles = [];
  DateTime? _scheduledFor;
  String? _selectedChannelId;
  NotificationChannel? _selectedChannel;

  final List<String> _types = ['booking', 'payment', 'promotion', 'system'];
  final List<String> _priorities = ['low', 'normal', 'high', 'urgent'];
  final List<String> _roles = ['Admin', 'Owner', 'Client', 'Staff', 'Guest'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('معلومات الإشعار'),
          const SizedBox(height: 16),
          _buildTypeSelector(),
          const SizedBox(height: 16),
          _buildPrioritySelector(),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _titleController,
            label: 'عنوان الإشعار',
            hint: 'أدخل عنوان الإشعار',
            icon: CupertinoIcons.text_cursor,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال عنوان الإشعار';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _messageController,
            label: 'محتوى الإشعار',
            hint: 'أدخل محتوى الإشعار',
            icon: CupertinoIcons.doc_text,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال محتوى الإشعار';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (widget.isBroadcast) ...[
            _buildSectionTitle('الجمهور المستهدف'),
            const SizedBox(height: 16),
            _buildChannelSelector(),
            const SizedBox(height: 16),
            _buildTargetAllSwitch(),
            if (!_targetAll) ...[
              const SizedBox(height: 16),
              _buildRolesSelector(),
              const SizedBox(height: 16),
              _buildMultiUsersSelector(),
            ],
            const SizedBox(height: 16),
            _buildScheduleSelector(),
          ] else ...[
            _buildSectionTitle('المستلم'),
            const SizedBox(height: 16),
            _buildRecipientSelector(),
          ],
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppTheme.textWhite,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الإشعار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedType = type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected
                      ? null
                      : AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getTypeLabel(type),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأولوية',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priorities.map((priority) {
            final isSelected = _selectedPriority == priority;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedPriority = priority);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getPriorityColor(priority)
                      : AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _getPriorityColor(priority).withValues(alpha: 0.5)
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getPriorityLabel(priority),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            prefixIcon: maxLines == 1
                ? Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: AppTheme.inputBackground.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.error,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قناة الإرسال (اختياري)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openChannelSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedChannelId != null
                    ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.speaker_2,
                  color: _selectedChannelId != null
                      ? AppTheme.primaryBlue
                      : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedChannelId != null
                        ? (_selectedChannel?.name ?? 'قناة محددة')
                        : 'إرسال عبر قناة محددة (اختياري)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedChannelId != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedChannelId != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedChannelId = null;
                        _selectedChannel = null;
                      });
                    },
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAllSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.person_3_fill,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إرسال للجميع',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'إرسال الإشعار لجميع المستخدمين',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _targetAll,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _targetAll = value);
            },
            activeTrackColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأدوار المستهدفة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roles.map((role) {
            final isSelected = _selectedRoles.contains(role);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedRoles.remove(role);
                  } else {
                    _selectedRoles.add(role);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                      : AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      _getRoleLabel(role),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جدولة الإرسال (اختياري)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectScheduleDateTime(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _scheduledFor != null
                    ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  color: _scheduledFor != null
                      ? AppTheme.primaryBlue
                      : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _scheduledFor != null
                        ? _formatScheduledDateTime(_scheduledFor!)
                        : 'اختر تاريخ ووقت الجدولة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _scheduledFor != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (_scheduledFor != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _scheduledFor = null);
                    },
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleSubmit,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isBroadcast
                      ? CupertinoIcons.paperplane_fill
                      : CupertinoIcons.bell_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isBroadcast ? 'بث الإشعار' : 'إرسال الإشعار',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      final formData = <String, dynamic>{
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
      };

      if (widget.isBroadcast) {
        formData['targetAll'] = _targetAll;
        formData['channelId'] = _selectedChannelId; // Use the selected channel
        if (!_targetAll) {
          formData['roles'] = _selectedRoles.isEmpty
              ? null
              : _selectedRoles.map(_mapRoleValue).toList();
          final uniqueIds = _selectedUsers.map((u) => u.id).toSet().toList();
          formData['userIds'] = uniqueIds.isEmpty ? null : uniqueIds;
        }
        formData['scheduledFor'] = _scheduledFor;
      } else {
        formData['recipientId'] =
            _selectedRecipient?.id ?? _recipientController.text.trim();
      }

      widget.onSubmit(formData);
    }
  }

  Future<void> _openChannelSelector() async {
    HapticFeedback.lightImpact();
    final ds = di.sl<NotificationChannelsRemoteDataSource>();
    final channels = await ds.getChannels(page: 1, pageSize: 100);
    if (!mounted) return;
    final selected = await showModalBottomSheet<NotificationChannel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: channels.length,
                separatorBuilder: (_, __) => Divider(color: AppTheme.darkBorder.withValues(alpha: 0.2)),
                itemBuilder: (context, index) {
                  final ch = channels[index];
                  final isSelected = _selectedChannelId == ch.id;
                  return ListTile(
                    dense: true,
                    onTap: () => Navigator.pop(ctx, ch),
                    leading: Icon(CupertinoIcons.speaker_2, color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted, size: 20),
                    title: Text(
                      ch.name,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      ch.identifier,
                      style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected ? Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primaryBlue, size: 20) : null,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _selectedChannel = selected;
        _selectedChannelId = selected.id;
      });
    }
  }

  Widget _buildRecipientSelector() {
    return GestureDetector(
      onTap: () async {
        final user = await SearchNavigationHelper.searchSingleUser(context);
        if (user != null) {
          setState(() {
            _selectedRecipient = user;
            _recipientController.text = user.id;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.inputBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.person_crop_circle_badge_checkmark,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedRecipient?.name ?? 'اختر مستخدماً لاستلام الإشعار',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedRecipient == null
                      ? AppTheme.textMuted
                      : AppTheme.textWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_back,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiUsersSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'اختيار مستخدمين محددين (اختياري)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final users =
                    await SearchNavigationHelper.searchMultipleUsers(context);
                if (users != null && users.isNotEmpty) {
                  setState(() {
                    // add unique by id
                    for (final u in users) {
                      if (_selectedUsers.indexWhere((x) => x.id == u.id) ==
                          -1) {
                        _selectedUsers.add(u);
                      }
                    }
                  });
                }
              },
              icon: const Icon(CupertinoIcons.person_crop_circle_badge_plus),
              label: const Text('اختيار'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedUsers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedUsers.map((u) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.darkBorder.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      u.name,
                      style: AppTextStyles.caption
                          .copyWith(color: AppTheme.textWhite),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUsers.removeWhere((x) => x.id == u.id);
                        });
                      },
                      child: Icon(CupertinoIcons.xmark_circle_fill,
                          size: 16, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _selectScheduleDateTime(BuildContext context) async {
    HapticFeedback.lightImpact();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhiteAlways,
              onPrimary: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppTheme.darkCard),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.darkCard,
              headerForegroundColor: AppTheme.textWhiteAlways,
              dayForegroundColor:
                  MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.textMuted;
                }
                return AppTheme.textWhiteAlways;
              }),
              dayBackgroundColor:
                  MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return Colors.transparent;
              }),
              todayForegroundColor:
                  MaterialStatePropertyAll(AppTheme.primaryBlue),
              todayBackgroundColor:
                  const MaterialStatePropertyAll(Colors.transparent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppTheme.primaryBlue,
                surface: AppTheme.darkCard,
                onSurface: AppTheme.textWhiteAlways,
                onPrimary: Colors.white,
              ),
              dialogTheme: DialogThemeData(backgroundColor: AppTheme.darkCard),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: AppTheme.darkCard,
                dialBackgroundColor: AppTheme.darkSurface,
                dialHandColor: AppTheme.primaryBlue,
                dialTextColor: AppTheme.textWhiteAlways,
                hourMinuteColor: AppTheme.darkSurface,
                hourMinuteTextColor: AppTheme.textWhiteAlways,
                dayPeriodTextColor: AppTheme.textWhiteAlways,
                entryModeIconColor: AppTheme.textWhiteAlways,
                helpTextStyle: TextStyle(color: AppTheme.textMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledFor = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatScheduledDateTime(DateTime dateTime) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year} - $hour:$minute';
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'booking':
        return 'الحجوزات';
      case 'payment':
        return 'المدفوعات';
      case 'promotion':
        return 'العروض';
      case 'system':
        return 'النظام';
      default:
        return type;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'منخفضة';
      case 'normal':
        return 'عادية';
      case 'high':
        return 'عالية';
      case 'urgent':
        return 'عاجلة';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppTheme.info;
      case 'normal':
        return AppTheme.primaryBlue;
      case 'high':
        return AppTheme.warning;
      case 'urgent':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'Admin':
        return 'مدير';
      case 'Owner':
        return 'مالك';
      case 'Staff':
        return 'طاقم (Staff)';
      case 'Client':
        return 'عميل';
      default:
        return role;
    }
  }

  String _mapRoleValue(String role) {
    // Canonicalize selected value to 5 roles
    switch (role) {
      case 'Admin':
        return 'Admin';
      case 'Owner':
        return 'Owner';
      case 'Client':
        return 'Client';
      case 'Staff':
        return 'Staff';
      case 'Guest':
        return 'Guest';
      default:
        return role;
    }
  }
}
