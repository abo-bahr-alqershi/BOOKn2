// lib/features/home/presentation/pages/section_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/section.dart';
import '../../../../core/enums/section_type_enum.dart';
import '../../../../core/enums/section_target_enum.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/sections/base_section_widget.dart';

class SectionDetailsPage extends StatefulWidget {
  final String sectionId;
  final Section? section;

  const SectionDetailsPage({super.key, required this.sectionId, this.section});

  @override
  State<SectionDetailsPage> createState() => _SectionDetailsPageState();
}

class _SectionDetailsPageState extends State<SectionDetailsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<HomeBloc>();
    final state = bloc.state;
    if (state is! HomeLoaded || state.sectionData[widget.sectionId] == null) {
      bloc.add(LoadSectionDataEvent(sectionId: widget.sectionId));
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 200) {
      final state = context.read<HomeBloc>().state;
      if (state is HomeLoaded) {
        final isLoadingMore =
            state.sectionsLoadingMore[widget.sectionId] ?? false;
        if (!isLoadingMore) {
          context
              .read<HomeBloc>()
              .add(LoadMoreSectionDataEvent(sectionId: widget.sectionId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.section?.title?.trim().isNotEmpty == true
              ? widget.section!.title!.trim()
              : (widget.section?.name ?? 'عرض القسم'),
          style: AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeLoaded) {
            Section section;
            if (widget.section != null) {
              section = widget.section!;
            } else {
              Section? found;
              try {
                found =
                    state.sections.firstWhere((s) => s.id == widget.sectionId);
              } catch (_) {}
              if (found != null) {
                section = found;
              } else {
                final fallbackBase =
                    state.sections.isNotEmpty ? state.sections.first : null;
                section = Section(
                  id: widget.sectionId,
                  type:
                      fallbackBase?.type ?? SectionType.horizontalPropertyList,
                  uiType: fallbackBase?.uiType ??
                      SectionType.horizontalPropertyList,
                  displayOrder: 0,
                  target: fallbackBase?.target ?? SectionTarget.properties,
                  isActive: true,
                  title: 'عرض القسم',
                );
              }
            }
            final sectionData = state.sectionData[widget.sectionId];
            final isLoadingMore =
                state.sectionsLoadingMore[widget.sectionId] ?? false;

            return RefreshIndicator(
              color: AppTheme.primaryBlue,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                context.read<HomeBloc>().add(
                      LoadSectionDataEvent(
                        sectionId: widget.sectionId,
                        pageNumber: 1,
                        forceRefresh: true,
                      ),
                    );
              },
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  BaseSectionWidget(
                    section: section,
                    data: sectionData,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: () {
                      context.read<HomeBloc>().add(
                            LoadMoreSectionDataEvent(
                              sectionId: widget.sectionId,
                            ),
                          );
                    },
                    onItemTap: (propertyId) {
                      if (propertyId.isNotEmpty) {
                        context.push('/property/$propertyId');
                      }
                    },
                  ),
                ],
              ),
            );
          }

          if (state is HomeError) {
            return Center(
              child: Text(
                state.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.error),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
