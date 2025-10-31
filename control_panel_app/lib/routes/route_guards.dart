import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_state.dart';

bool isAuthenticated(AuthState state) => state is AuthAuthenticated;

bool isAdmin(AuthState state) {
  if (state is! AuthAuthenticated) return false;
  final accountRole = (state.user.accountRole ?? '').toLowerCase();
  if (accountRole == 'admin' || accountRole == 'owner') return true;
  final roles = state.user.roles.map((e) => e.toLowerCase()).toList();
  return roles.contains('admin') || roles.contains('superadmin') || roles.contains('super_admin') || roles.contains('owner');
}

bool isAdminPath(String path) => path.startsWith('/admin');

bool isProtectedPath(String path) {
  return path.startsWith('/profile') ||
      path.startsWith('/conversations') ||
      path.startsWith('/chat') ||
      path.startsWith('/notifications') ||
      path.startsWith('/admin');
}

