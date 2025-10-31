// lib/features/admin_reviews/presentation/pages/review_details_page.dart

import 'package:bookn_cp_app/core/widgets/loading_widget.dart';

import '../../../../injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review.dart';
import '../bloc/review_details/review_details_bloc.dart';
import '../widgets/review_images_gallery.dart';
import '../widgets/review_response_card.dart';
import '../widgets/add_response_dialog.dart';
import '../widgets/rating_breakdown_widget.dart';
import '../../domain/usecases/approve_review_usecase.dart';

class ReviewDetailsPage extends StatefulWidget {
  final String reviewId;

  const ReviewDetailsPage({
    super.key,
    required this.reviewId,
  });

  @override
  State<ReviewDetailsPage> createState() => _ReviewDetailsPageState();
}

class _ReviewDetailsPageState extends State<ReviewDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  bool _isApproving = false;

  TextDirection _getTextDirection(String? text) {
    if (text == null || text.trim().isEmpty) return TextDirection.ltr;
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));

    _mainAnimationController.forward();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showFloatingHeader) {
        setState(() {
          _showFloatingHeader = shouldShow;
        });
      }
    });

    context
        .read<ReviewDetailsBloc>()
        .add(LoadReviewDetailsEvent(widget.reviewId));
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocBuilder<ReviewDetailsBloc, ReviewDetailsState>(
        builder: (context, state) {
          if (state is ReviewDetailsLoading) {
            return const LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل تفاصيل التقييم...',
            );
          }

          if (state is ReviewDetailsError) {
            return _buildErrorState(state.message);
          }

          if (state is ReviewDetailsLoaded) {
            return Stack(
              children: [
                // خلفية متحركة
                _buildAnimatedBackground(),

                // المحتوى الرئيسي
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // شريط التطبيق مع صورة البطل
                    _buildHeroAppBar(context, state.review, isDesktop),

                    // محتوى التقييم
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildReviewContent(
                            context,
                            state.review,
                            state.responses,
                            isDesktop,
                            isTablet,
                          ),
                        ),
                      ),
                    ),

                    // حشوة سفلية
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),

                // الرأس العائم
                if (_showFloatingHeader)
                  _buildFloatingHeader(context, state.review),

                // الأزرار العائمة
                _buildFloatingActions(context, state.review),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // خلفية متدرجة
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
              ],
            ),
          ),
        ),

        // كرات عائمة
        Positioned(
          top: 100,
          left: -50,
          child: AnimatedBuilder(
            animation: _floatingAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  20 * _floatingAnimationController.value,
                ),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.15),
                        AppTheme.primaryBlue.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          bottom: 200,
          right: -100,
          child: AnimatedBuilder(
            animation: _floatingAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -15 * _floatingAnimationController.value,
                ),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryPurple.withOpacity(0.1),
                        AppTheme.primaryPurple.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAppBar(
    BuildContext context,
    Review review,
    bool isDesktop,
  ) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 320 : 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildBackButton(context),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // صورة الخلفية أو التدرج
            if (review.images.isNotEmpty)
              Image.network(
                review.images.first.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildGradientBackground(),
              )
            else
              _buildGradientBackground(),

            // تدرج التراكب
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBackground.withOpacity(0.7),
                    AppTheme.darkBackground,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // معلومات التقييم
            Positioned(
              bottom: 40,
              left: isDesktop ? 32 : 20,
              right: isDesktop ? 32 : 20,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المستخدم
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.glowBlue.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              review.userName.substring(0, 2).toUpperCase(),
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 16,
                                    color: AppTheme.textLight.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      review.propertyName,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color:
                                            AppTheme.textLight.withOpacity(0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // شارة الحالة
                        _buildStatusBadge(review),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // التقييم
                    _buildRatingStars(review.averageRating),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.3),
            AppTheme.primaryPurple.withOpacity(0.3),
            AppTheme.primaryViolet.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.inputBackground.withOpacity(0.5),
        border: Border.all(
          color: AppTheme.glowBlue.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.textWhite,
          size: 20,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildStatusBadge(Review review) {
    final color = review.isPending
        ? AppTheme.warning
        : review.isApproved
            ? AppTheme.success
            : AppTheme.error;

    final text = review.isPending
        ? 'قيد المراجعة'
        : review.isApproved
            ? 'مُعتمد'
            : 'مرفوض';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating.floor();
        final halfFilled = index == rating.floor() && rating % 1 != 0;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            halfFilled
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            color: AppTheme.warning,
            size: 28,
          ),
        );
      }),
    );
  }

  Widget _buildReviewContent(
    BuildContext context,
    Review review,
    List<dynamic> responses,
    bool isDesktop,
    bool isTablet,
  ) {
    final horizontalPadding = isDesktop ? 32.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // تفصيل التقييم
          ScaleTransition(
            scale: _scaleAnimation,
            child: RatingBreakdownWidget(
              cleanliness: review.cleanliness,
              service: review.service,
              location: review.location,
              value: review.value,
              isDesktop: isDesktop,
            ),
          ),

          const SizedBox(height: 32),

          // قسم التعليق
          _buildCommentSection(review),

          const SizedBox(height: 32),

          // معرض الصور
          if (review.images.isNotEmpty) ...[
            _buildSectionTitle('صور التقييم'),
            const SizedBox(height: 16),
            ReviewImagesGallery(
              images: review.images,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 32),
          ],

          // معلومات التقييم
          _buildInfoSection(review),

          const SizedBox(height: 32),

          // قسم الردود
          _buildResponsesSection(context, review, responses),
        ],
      ),
    );
  }

  Widget _buildCommentSection(Review review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: AppTheme.glowBlue.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'تعليق التقييم',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SelectableText(
            review.comment,
            textDirection: _getTextDirection(review.comment),
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.6,
              color: AppTheme.textLight,
              fontFamilyFallback: const ['Amiri','Noto Naskh Arabic','Roboto'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Review review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.inputBackground.withOpacity(0.3),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'رقم الحجز',
            value: review.bookingId,
          ),
          const SizedBox(height: 16),
          if (review.unitName != null && review.unitName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.meeting_room_outlined,
              label: 'اسم الوحدة',
              value: review.unitName!,
            ),
            const SizedBox(height: 16),
          ],
          if (review.propertyCity != null &&
              review.propertyCity!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.location_city_outlined,
              label: 'المدينة',
              value: review.propertyCity!,
            ),
            const SizedBox(height: 16),
          ],
          if (review.propertyAddress != null &&
              review.propertyAddress!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.place_outlined,
              label: 'العنوان',
              value: review.propertyAddress!,
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ التقييم',
            value: _formatDate(review.createdAt),
          ),
          if (review.bookingCheckIn != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.login_outlined,
              label: 'تسجيل الوصول',
              value: _formatDate(review.bookingCheckIn!),
            ),
          ],
          if (review.bookingCheckOut != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.logout_outlined,
              label: 'تسجيل المغادرة',
              value: _formatDate(review.bookingCheckOut!),
            ),
          ],
          if (review.guestsCount != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.group_outlined,
              label: 'عدد الضيوف',
              value: review.guestsCount!.toString(),
            ),
          ],
          if (review.bookingStatus != null &&
              review.bookingStatus!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.assignment_turned_in_outlined,
              label: 'حالة الحجز',
              value: review.bookingStatus!,
            ),
          ],
          if (review.bookingSource != null &&
              review.bookingSource!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.public_outlined,
              label: 'مصدر الحجز',
              value: review.bookingSource!,
            ),
          ],
          if (review.userEmail != null && review.userEmail!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني للعميل',
              value: review.userEmail!,
            ),
          ],
          if (review.userPhone != null && review.userPhone!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'رقم هاتف العميل',
              value: review.userPhone!,
            ),
          ],
          if (review.hasResponse) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.reply_outlined,
              label: 'تاريخ الرد',
              value: _formatDate(review.responseDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.primaryBlue.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsesSection(
    BuildContext context,
    Review review,
    List<dynamic> responses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('ردود الإدارة'),
            IconButton(
              onPressed: () => _showAddResponseDialog(context, review.id),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (responses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.inputBackground.withOpacity(0.3),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد ردود حتى الآن',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف رداً على هذا التقييم',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: responses.map((response) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewResponseCard(
                      response: response,
                      onDelete: () {
                        context.read<ReviewDetailsBloc>().add(
                              DeleteResponseEvent(response.id),
                            );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
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

  Widget _buildFloatingHeader(BuildContext context, Review review) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: _showFloatingHeader ? 0 : -100,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.only(
              top: 48,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.glowBlue.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildBackButton(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        review.userName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.averageRating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppTheme.warning,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(review),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context, Review review) {
    final bool isApproving = _isApproving;
    return Positioned(
      bottom: 32,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (review.isPending) ...[
            isApproving
                ? _buildLoadingFloatingButton(color: AppTheme.success)
                : _buildFloatingActionButton(
                    icon: Icons.check,
                    color: AppTheme.success,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showApproveConfirmation(context, widget.reviewId);
                    },
                  ),
            const SizedBox(height: 12),
            _buildFloatingActionButton(
              icon: Icons.close,
              color: AppTheme.error,
              onTap: () {
                HapticFeedback.mediumImpact();
                // context.read<ReviewsListBloc>().add(
                //   RejectReviewEvent(widget.reviewId),
                // );
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildFloatingActionButton(
            icon: Icons.reply,
            color: AppTheme.primaryBlue,
            onTap: () => _showAddResponseDialog(context, review.id),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingFloatingButton({required Color color}) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showApproveConfirmation(BuildContext context, String reviewId) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الموافقة على التقييم؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم اعتماد هذا التقييم. هل تريد المتابعة؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveReview(reviewId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'موافقة',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveReview(String reviewId) async {
    if (_isApproving) return;
    setState(() {
      _isApproving = true;
    });
    try {
      final useCase = di.sl<ApproveReviewUseCase>();
      final result = await useCase(reviewId);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (_) {
          // Refresh details after approval
          if (mounted) {
            context.read<ReviewDetailsBloc>().add(RefreshReviewDetailsEvent());
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowBlue.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'جاري تحميل تفاصيل التقييم...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.error.withOpacity(0.1),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'خطأ في تحميل التقييم',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ReviewDetailsBloc>().add(
                    LoadReviewDetailsEvent(widget.reviewId),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              'حاول مرة أخرى',
              style: AppTextStyles.buttonMedium,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResponseDialog(BuildContext context, String reviewId) {
    HapticFeedback.lightImpact();

    // Capture the bloc from the current (correct) context
    final reviewDetailsBloc = context.read<ReviewDetailsBloc>();

    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(5),
          child: BlocProvider.value(
            value: reviewDetailsBloc,
            child: AddResponseDialog(
              reviewId: reviewId,
              onSubmit: (responseText) {
                // Use the captured bloc to avoid ProviderNotFound in dialog builder context
                reviewDetailsBloc.add(
                  AddResponseEvent(
                    reviewId: reviewId,
                    responseText: responseText,
                    // اتركه فارغًا ليقوم الداتا سورس باستخدام userId المخزن أو تجاهله
                    respondedBy: '',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}، ${date.year}';
  }
}
