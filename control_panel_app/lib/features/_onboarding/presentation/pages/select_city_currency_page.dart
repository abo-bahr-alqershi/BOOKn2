// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/theme/app_theme.dart';
// import 'package:bookn_cp_app/injection_container.dart' as di;
// import 'package:bookn_cp_app/features/admin_currencies/domain/usecases/get_currencies_usecase.dart';
// import 'package:bookn_cp_app/features/admin_cities/domain/usecases/get_cities_usecase.dart'
//     as ci_uc;
// import 'package:bookn_cp_app/core/usecases/usecase.dart';
// import '../../../../injection_container.dart';
// import '../../../../services/local_storage_service.dart';
// import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../features/auth/presentation/bloc/auth_state.dart';

// class SelectCityCurrencyPage extends StatefulWidget {
//   const SelectCityCurrencyPage({super.key});

//   @override
//   State<SelectCityCurrencyPage> createState() => _SelectCityCurrencyPageState();
// }

// class _SelectCityCurrencyPageState extends State<SelectCityCurrencyPage> {
//   List<String> _cities = const [];
//   List<String> _currencies = const [];
//   String? _city;
//   String? _currency;
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     final storage = sl<LocalStorageService>();
//     try {
//       // Load currencies
//       final curUsecase = di.sl<GetCurrenciesUseCase>();
//       final curRes = await curUsecase(NoParams());
//       curRes.fold((f) {}, (list) {
//         _currencies = list.map((c) => c.code).toList();
//       });
//       // Load cities
//       final citiesUsecase = di.sl<ci_uc.GetCitiesUseCase>();
//       final citiesRes = await citiesUsecase(const ci_uc.GetCitiesParams());
//       citiesRes.fold((f) {}, (list) {
//         _cities = list.map((c) => c.name).toList();
//       });
//       _city = storage.getSelectedCity().isNotEmpty
//           ? storage.getSelectedCity()
//           : null;
//       _currency = storage.getSelectedCurrency();
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.darkBackground,
//       appBar: AppBar(
//         title: const Text('اختيار المدينة والعملة'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: _loading
//             ? const Center(child: CircularProgressIndicator())
//             : (_error != null
//                 ? _buildErrorView(_error!)
//                 : Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('اختر مدينتك',
//                           style: TextStyle(
//                               color: AppTheme.textWhite,
//                               fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 8),
//                       _buildDropdown<String>(
//                         value: _city,
//                         hint: 'اختر المدينة',
//                         items: _cities,
//                         onChanged: (v) => setState(() => _city = v),
//                       ),
//                       const SizedBox(height: 16),
//                       Text('اختر عملتك',
//                           style: TextStyle(
//                               color: AppTheme.textWhite,
//                               fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 8),
//                       _buildDropdown<String>(
//                         value: _currency,
//                         hint: 'اختر العملة',
//                         items: _currencies,
//                         onChanged: (v) => setState(() => _currency = v),
//                       ),
//                       const Spacer(),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _city == null || _currency == null
//                               ? null
//                               : _continue,
//                           child: const Text('متابعة'),
//                         ),
//                       ),
//                     ],
//                   )),
//       ),
//     );
//   }

//   Widget _buildDropdown<T>(
//       {required T? value,
//       required String hint,
//       required List<T> items,
//       required ValueChanged<T?> onChanged}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: AppTheme.inputBackground,
//         border: Border.all(color: AppTheme.inputBorder),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: DropdownButton<T>(
//         value: value,
//         items: items
//             .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
//             .toList(),
//         onChanged: onChanged,
//         isExpanded: true,
//         underline: const SizedBox.shrink(),
//         hint: Text(hint),
//       ),
//     );
//   }

//   Widget _buildErrorView(String message) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'فشل تحميل البيانات',
//             style: TextStyle(
//                 color: AppTheme.textWhite, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: TextStyle(color: AppTheme.textLight),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _loading = true;
//                 _error = null;
//               });
//               _load();
//             },
//             child: const Text('إعادة المحاولة'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _continue() async {
//     final storage = sl<LocalStorageService>();
//     await storage.saveSelectedCity(_city!);
//     await storage.saveSelectedCurrency(_currency!);
//     await storage.setOnboardingCompleted(true);
//     final authState = context.read<AuthBloc>().state;
//     if (authState is AuthAuthenticated) {
//       if (!mounted) return;
//       context.go('/main');
//     } else {
//       if (!mounted) return;
//       context.go('/login');
//     }
//   }
// }
