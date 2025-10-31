// lib/features/home/presentation/pages/all_sections_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../widgets/sections/base_section_widget.dart';

class AllSectionsPage extends StatefulWidget {
  const AllSectionsPage({super.key});

  @override
  State<AllSectionsPage> createState() => _AllSectionsPageState();
}

class _AllSectionsPageState extends State<AllSectionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    final homeBloc = context.read<HomeBloc>();
    if (homeBloc.state is! HomeLoaded) {
      homeBloc.add(const LoadHomeDataEvent());
    }
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.darkGradient,
            ),
          ),
          
          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar
              _buildAppBar(),
              
              // Filter chips
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),
              
              // Sections list
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoaded) {
                    final filteredSections = _filterSections(state.sections);
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = filteredSections[index];
                          final sectionData = state.sectionData[section.id];
                          
                          return BaseSectionWidget(
                            section: section,
                            data: sectionData,
                            onViewAll: () {
                              context.push('/section/${section.id}', extra: section);
                            },
                          );
                        },
                        childCount: filteredSections.length,
                      ),
                    );
                  }
                  
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground.withOpacity(0.95),
              AppTheme.darkSurface.withOpacity(0.9),
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: FlexibleSpaceBar(
              title: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'جميع الأقسام',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'الكل',
      'عروض',
      'إعلانات',
      'عقارات',
      'وجهات',
      'مميز',
    ];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter ||
              (_selectedFilter == null && filter == 'الكل');
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter == 'الكل' ? null : filter;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: !isSelected ? AppTheme.darkCard.withOpacity(0.5) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                filter,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _filterSections(List<dynamic> sections) {
    if (_selectedFilter == null) {
      return sections;
    }
    
    // Filter logic based on section type
    return sections.where((section) {
      // Implement filter logic
      return true;
    }).toList();
  }
}