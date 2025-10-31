// lib/features/admin_properties/presentation/pages/property_types_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/property_types/property_types_bloc.dart';

class PropertyTypesPage extends StatefulWidget {
  const PropertyTypesPage({super.key});
  
  @override
  State<PropertyTypesPage> createState() => _PropertyTypesPageState();
}

class _PropertyTypesPageState extends State<PropertyTypesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPropertyTypes();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  void _loadPropertyTypes() {
    context.read<PropertyTypesBloc>().add(const LoadPropertyTypesEvent());
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.7),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withValues(alpha: 0.5),
                    AppTheme.darkSurface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'أنواع العقارات',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة أنواع العقارات المتاحة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return BlocBuilder<PropertyTypesBloc, PropertyTypesState>(
      builder: (context, state) {
        if (state is PropertyTypesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is PropertyTypesError) {
          return Center(
            child: Text(
              state.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.error,
              ),
            ),
          );
        }
        
        if (state is PropertyTypesLoaded) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.propertyTypes.length,
            itemBuilder: (context, index) {
              final type = state.propertyTypes[index];
              return _PropertyTypeCard(
                propertyType: type,
                onEdit: () => _showEditDialog(type),
                onDelete: () => _showDeleteConfirmation(type.id),
              );
            },
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateDialog,
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }
  
  void _showCreateDialog() {
    // Show create dialog
  }
  
  void _showEditDialog(dynamic type) {
    // Show edit dialog
  }
  
  void _showDeleteConfirmation(String id) {
    // Show delete confirmation
  }
}

class _PropertyTypeCard extends StatelessWidget {
  final dynamic propertyType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _PropertyTypeCard({
    required this.propertyType,
    required this.onEdit,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.5),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyType.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${propertyType.propertiesCount} عقار',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppTheme.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}