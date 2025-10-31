class RouteConstants {
  RouteConstants._();
  
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  
  // Main Routes
  static const String main = '/main';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchResults = '/search/results';
  static const String searchFilters = '/search/filters';
  
  // Property Routes
  static const String propertyDetails = '/property/:id';
  static const String propertyGallery = '/property/:id/gallery';
  static const String propertyReviews = '/property/:id/reviews';
  static const String propertyMap = '/property/:id/map';
  
  // Booking Routes
  static const String bookingForm = '/booking/form';
  static const String bookingSummary = '/booking/summary';
  static const String bookingPayment = '/booking/payment';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String myBookings = '/bookings';
  static const String bookingDetails = '/booking/:id';
  
  // User Routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String favorites = '/favorites';
  static const String paymentMethods = '/payment/methods';
  static const String addPaymentMethod = '/payment/add-method';
  static const String paymentHistory = '/payment/history';
  
  // Chat Routes
  static const String conversations = '/chat/conversations';
  static const String chat = '/chat/:conversationId';
  static const String chatSettings = '/chat/settings';
  
  // Notifications Routes
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  
  // Settings Routes
  static const String settings = '/settings';
  static const String languageSettings = '/settings/language';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String about = '/settings/about';
  
  // Nested Routes / Parameters Example
  static String buildPropertyDetailsRoute(String id) => '/property/$id';
  static String buildBookingDetailsRoute(String id) => '/booking/$id';
  static String buildChatRouteWithId(String conversationId) => '/chat/$conversationId';
}