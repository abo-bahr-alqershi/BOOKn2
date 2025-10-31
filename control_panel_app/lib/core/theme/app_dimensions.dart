// class AppDimensions {
//   AppDimensions._();
  
//   // Padding & Margin
//   static const double paddingXSmall = 4.0;
//   static const double paddingSmall = 8.0;
//   static const double paddingMedium = 16.0;
//   static const double paddingLarge = 24.0;
//   static const double paddingXLarge = 32.0;
//   static const double paddingXXLarge = 48.0;
  
//   // Spacing
//   static const double spaceXSmall = 4.0;
//   static const double spaceSmall = 8.0;
//   static const double spaceMedium = 16.0;
//   static const double spaceLarge = 24.0;
//   static const double spaceXLarge = 32.0;
//   static const double spaceXXLarge = 48.0;
  
//   // Spacing aliases for theme compatibility
//   static const double spacingXs = spaceXSmall;
//   static const double spacingSm = spaceSmall;
//   static const double spacingMd = spaceMedium;
//   static const double spacingLg = spaceLarge;
//   static const double spacingXl = spaceXLarge;
  
//   // Border Radius
//   static const double radiusXSmall = 4.0;
//   static const double radiusSmall = 8.0;
//   static const double radiusMedium = 12.0;
//   static const double radiusLarge = 16.0;
//   static const double radiusXLarge = 24.0;
//   static const double radiusXXLarge = 32.0;
//   static const double radiusCircular = 999.0;
  
//   // Border Radius aliases for theme compatibility
//   static const double borderRadiusXs = radiusXSmall;
//   static const double borderRadiusSm = radiusSmall;
//   static const double borderRadiusMd = radiusMedium;
//   static const double borderRadiusLg = radiusLarge;
//   static const double borderRadiusXl = radiusXLarge;
  
//   // Icon Sizes
//   static const double iconXSmall = 16.0;
//   static const double iconSmall = 20.0;
//   static const double iconMedium = 24.0;
//   static const double iconLarge = 32.0;
//   static const double iconXLarge = 48.0;
//   static const double iconXXLarge = 64.0;
  
//   // Component Heights
//   static const double buttonHeightSmall = 36.0;
//   static const double buttonHeightMedium = 48.0;
//   static const double buttonHeightLarge = 56.0;
//   static const double inputHeight = 56.0;
//   static const double appBarHeight = 56.0;
//   static const double bottomBarHeight = 64.0;
//   static const double cardHeight = 120.0;
//   static const double listItemHeight = 72.0;
  
//   // Component Widths
//   static const double buttonWidthSmall = 96.0;
//   static const double buttonWidthMedium = 120.0;
//   static const double buttonWidthLarge = 180.0;
//   static const double maxContentWidth = 600.0;
  
//   // Elevation
//   static const double elevationXSmall = 1.0;
//   static const double elevationSmall = 2.0;
//   static const double elevationMedium = 4.0;
//   static const double elevationLarge = 8.0;
//   static const double elevationXLarge = 16.0;
  
//   // Border Width
//   static const double borderThin = 1.0;
//   static const double borderMedium = 2.0;
//   static const double borderThick = 3.0;
  
//   // Blur Radius
//   static const double blurSmall = 4.0;
//   static const double blurMedium = 8.0;
//   static const double blurLarge = 16.0;
  
//   // Image Dimensions
//   static const double thumbnailSize = 80.0;
//   static const double avatarSizeSmall = 32.0;
//   static const double avatarSizeMedium = 48.0;
//   static const double avatarSizeLarge = 64.0;
//   static const double propertyImageHeight = 200.0;
//   static const double galleryImageHeight = 300.0;
  
//   // Map Dimensions
//   static const double mapHeight = 200.0;
//   static const double mapMarkerSize = 40.0;
  
//   // Animation Durations (in milliseconds)
//   static const int animationFast = 200;
//   static const int animationNormal = 300;
//   static const int animationSlow = 500;
  
//   // Grid
//   static const int gridColumns = 2;
//   static const double gridSpacing = 16.0;
//   static const double gridAspectRatio = 1.2;
// }
import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();
  
  // ============= Responsive Breakpoints =============
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  static const double largeDesktopBreakpoint = 1800.0;
  
  // ============= Premium Spacing System =============
  // Base unit for consistent spacing (8px grid system)
  static const double baseUnit = 8.0;
  
  // Padding & Margin - Premium spacing for breathing room
  static const double paddingXXSmall = 2.0;
  static const double paddingXSmall = 6.0;
  static const double paddingSmall = 12.0;
  static const double paddingMedium = 20.0;
  static const double paddingLarge = 32.0;
  static const double paddingXLarge = 48.0;
  static const double paddingXXLarge = 64.0;
  static const double paddingXXXLarge = 80.0;
  
  // Premium Content Padding
  static const double screenPaddingMobile = 20.0;
  static const double screenPaddingTablet = 32.0;
  static const double screenPaddingDesktop = 48.0;
  
  // Spacing - Generous spacing for minimalist design
  static const double spaceXXSmall = 2.0;
  static const double spaceXSmall = 6.0;
  static const double spaceSmall = 12.0;
  static const double spaceMedium = 20.0;
  static const double spaceLarge = 32.0;
  static const double spaceXLarge = 48.0;
  static const double spaceXXLarge = 64.0;
  static const double spaceXXXLarge = 96.0;
  
  // Section Spacing
  static const double sectionSpacingSmall = 40.0;
  static const double sectionSpacingMedium = 60.0;
  static const double sectionSpacingLarge = 80.0;
  
  // ============= Typography Dimensions =============
  // Font Sizes - Premium scale
  static const double textXXSmall = 10.0;
  static const double textXSmall = 12.0;
  static const double textSmall = 14.0;
  static const double textMedium = 16.0;
  static const double textLarge = 18.0;
  static const double textXLarge = 22.0;
  static const double textXXLarge = 28.0;
  
  // Headings - Display sizes
  static const double headingXSmall = 20.0;
  static const double headingSmall = 24.0;
  static const double headingMedium = 32.0;
  static const double headingLarge = 40.0;
  static const double headingXLarge = 48.0;
  static const double headingDisplay = 64.0;
  static const double headingHero = 80.0;
  
  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  static const double lineHeightLoose = 2.0;
  
  // Letter Spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingExtraWide = 1.0;
  
  // ============= Border Radius - Softer corners =============
  static const double radiusNone = 0.0;
  static const double radiusXSmall = 6.0;
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  static const double radiusXXLarge = 40.0;
  static const double radiusCircular = 999.0;
  
  // Border Radius aliases for theme compatibility
  static const double borderRadiusXs = radiusXSmall;
  
  // Card Specific Radius
  static const double cardRadius = 20.0;
  static const double cardRadiusSmall = 16.0;
  static const double modalRadius = 28.0;
  static const double bottomSheetRadius = 32.0;
  
  // ============= Icon Sizes =============
  static const double iconXXSmall = 14.0;
  static const double iconXSmall = 18.0;
  static const double iconSmall = 22.0;
  static const double iconMedium = 26.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 40.0;
  static const double iconXXLarge = 56.0;
  static const double iconHuge = 72.0;
  
  // ============= Component Heights =============
  // Buttons - Premium heights
  static const double buttonHeightXSmall = 36.0;
  static const double buttonHeightSmall = 44.0;
  static const double buttonHeightMedium = 52.0;
  static const double buttonHeightLarge = 60.0;
  static const double buttonHeightXLarge = 68.0;
  
  // Input Fields
  static const double inputHeightSmall = 48.0;
  static const double inputHeightMedium = 56.0;
  static const double inputHeightLarge = 64.0;
  
  // Navigation
  static const double appBarHeight = 64.0;
  static const double appBarHeightLarge = 72.0;
  static const double tabBarHeight = 56.0;
  static const double bottomNavHeight = 72.0;
  static const double bottomNavHeightWithLabel = 80.0;
  
  // Cards & Lists
  static const double cardHeightSmall = 100.0;
  static const double cardHeightMedium = 140.0;
  static const double cardHeightLarge = 200.0;
  static const double listItemHeightSmall = 64.0;
  static const double listItemHeightMedium = 80.0;
  static const double listItemHeightLarge = 96.0;
  
  // ============= Booking Specific Components =============
  // Property Cards
  static const double propertyCardHeight = 320.0;
  static const double propertyCardHeightCompact = 240.0;
  static const double propertyCardImageHeight = 200.0;
  static const double propertyCardImageHeightCompact = 140.0;
  
  // Featured Cards
  static const double featuredCardHeight = 400.0;
  static const double featuredCardWidth = 300.0;
  
  // Search Components
  static const double searchBarHeight = 64.0;
  static const double searchBarHeightExpanded = 72.0;
  static const double filterChipHeight = 40.0;
  static const double filterBarHeight = 56.0;
  
  // Calendar
  static const double calendarDaySize = 48.0;
  static const double calendarMonthHeight = 360.0;
  static const double dateRangePickerHeight = 400.0;
  
  // Booking Summary
  static const double bookingSummaryHeight = 180.0;
  static const double priceDisplayHeight = 80.0;
  
  // Reviews
  static const double reviewCardHeight = 160.0;
  static const double ratingStarSize = 20.0;
  static const double ratingStarSizeLarge = 28.0;
  
  // ============= Component Widths =============
  static const double buttonWidthSmall = 120.0;
  static const double buttonWidthMedium = 160.0;
  static const double buttonWidthLarge = 220.0;
  static const double buttonWidthFull = double.infinity;
  
  // Content Widths - Responsive
  static const double maxContentWidthMobile = 600.0;
  static const double maxContentWidthTablet = 900.0;
  static const double maxContentWidthDesktop = 1200.0;
  static const double maxContentWidthLarge = 1440.0;
  
  // Sidebar & Panels
  static const double sidebarWidthCompact = 72.0;
  static const double sidebarWidthMedium = 280.0;
  static const double sidebarWidthLarge = 320.0;
  static const double filterPanelWidth = 320.0;
  
  // ============= Elevation & Shadows =============
  static const double elevationNone = 0.0;
  static const double elevationXSmall = 1.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 12.0;
  static const double elevationXXLarge = 24.0;
  
  // Premium Shadow Values
  static const double shadowBlurXSmall = 4.0;
  static const double shadowBlurSmall = 8.0;
  static const double shadowBlurMedium = 16.0;
  static const double shadowBlurLarge = 24.0;
  static const double shadowBlurXLarge = 40.0;
  
  static const double shadowSpreadSubtle = -2.0;
  static const double shadowSpreadNormal = 0.0;
  static const double shadowSpreadWide = 4.0;
  
  // ============= Borders =============
  static const double borderNone = 0.0;
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;
  static const double borderBold = 3.0;
  
  // ============= Images & Media =============
  // Thumbnails
  static const double thumbnailSizeXSmall = 48.0;
  static const double thumbnailSizeSmall = 64.0;
  static const double thumbnailSizeMedium = 96.0;
  static const double thumbnailSizeLarge = 128.0;
  
  // Avatars
  static const double avatarSizeXSmall = 28.0;
  static const double avatarSizeSmall = 36.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;
  
  // Gallery
  static const double galleryImageHeight = 360.0;
  static const double galleryThumbnailSize = 80.0;
  static const double gallerySpacing = 12.0;
  
  // Hero Images
  static const double heroImageHeightMobile = 240.0;
  static const double heroImageHeightTablet = 360.0;
  static const double heroImageHeightDesktop = 480.0;
  
  // ============= Maps =============
  static const double mapHeightSmall = 200.0;
  static const double mapHeightMedium = 300.0;
  static const double mapHeightLarge = 400.0;
  static const double mapHeightFullscreen = double.infinity;
  static const double mapMarkerSize = 48.0;
  static const double mapClusterSize = 56.0;
  
  // ============= Animation =============
  static const int animationInstant = 0;
  static const int animationFast = 150;
  static const int animationNormal = 250;
  static const int animationSlow = 350;
  static const int animationSlowest = 500;
  
  // Premium Animation Curves
  static const Curve animationCurveDefault = Curves.easeInOutCubic;
  static const Curve animationCurveSharp = Curves.easeOutQuart;
  static const Curve animationCurveSmooth = Curves.easeInOutQuint;
  
  // ============= Grid System =============
  static const int gridColumnsMobile = 2;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsDesktop = 4;
  static const int gridColumnsLarge = 5;
  
  static const double gridSpacingSmall = 12.0;
  static const double gridSpacingMedium = 20.0;
  static const double gridSpacingLarge = 28.0;
  
  static const double gridAspectRatioSquare = 1.0;
  static const double gridAspectRatioLandscape = 1.33;
  static const double gridAspectRatioPortrait = 0.75;
  static const double gridAspectRatioWide = 1.77;
  
  // ============= Modals & Overlays =============
  static const double modalWidthSmall = 320.0;
  static const double modalWidthMedium = 480.0;
  static const double modalWidthLarge = 640.0;
  static const double modalMaxHeight = 0.9; // 90% of screen height
  
  static const double bottomSheetMaxHeight = 0.85;
  static const double bottomSheetMinHeight = 120.0;
  
  // ============= FAB & Floating Elements =============
  static const double fabSizeSmall = 48.0;
  static const double fabSizeMedium = 56.0;
  static const double fabSizeLarge = 64.0;
  static const double fabMargin = 16.0;
  
  // ============= Responsive Utilities =============
  static double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return screenPaddingMobile;
    if (width < tabletBreakpoint) return screenPaddingTablet;
    return screenPaddingDesktop;
  }
  
  static int getResponsiveGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return gridColumnsMobile;
    if (width < tabletBreakpoint) return gridColumnsTablet;
    if (width < desktopBreakpoint) return gridColumnsDesktop;
    return gridColumnsLarge;
  }
  
  static double getResponsiveContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return width;
    if (width < tabletBreakpoint) return maxContentWidthTablet;
    if (width < desktopBreakpoint) return maxContentWidthDesktop;
    return maxContentWidthLarge;
  }
  
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tabletBreakpoint;
}