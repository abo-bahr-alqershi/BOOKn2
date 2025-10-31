// injection_container.dart

import 'package:bookn_cp_app/features/admin_properties/data/datasources/property_images_remote_datasource.dart';
import 'package:bookn_cp_app/features/admin_properties/data/repositories/property_images_repository_impl.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/repositories/property_images_repository.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/delete_multiple_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/delete_property_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/get_property_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/reorder_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/set_primary_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/update_property_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/upload_multiple_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/usecases/property_images/upload_property_image_usecase.dart'; // إضافة هذا الاستيراد
import 'package:bookn_cp_app/features/admin_properties/presentation/bloc/property_images/property_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_sections/data/datasources/sections_local_datasource.dart';
import 'package:bookn_cp_app/features/admin_sections/data/datasources/sections_remote_datasource.dart';
import 'package:bookn_cp_app/features/admin_sections/data/repositories/sections_repository_impl.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/repositories/sections_repository.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/add_items_to_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/get_section_items_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/remove_items_from_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/update_item_order_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/create_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/delete_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/get_all_sections_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/get_section_by_id_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/toggle_section_status_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/update_section_usecase.dart';

import 'package:bookn_cp_app/features/admin_units/data/datasources/unit_images_remote_datasource.dart';
import 'package:bookn_cp_app/features/admin_units/data/repositories/unit_images_repository_impl.dart';
import 'package:bookn_cp_app/features/admin_units/domain/repositories/unit_images_repository.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/delete_multiple_unit_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/delete_unit_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/get_unit_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/reorder_unit_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/set_primary_unit_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/update_unit_image_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/upload_multiple_unit_images_usecase.dart';
import 'package:bookn_cp_app/features/admin_units/domain/usecases/unit_images/upload_unit_image_usecase.dart'; // إضافة هذا الاستيراد
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_bloc.dart';
import 'package:bookn_cp_app/services/data_sync_service.dart';
import 'package:bookn_cp_app/services/local_data_service.dart';
import 'package:bookn_cp_app/services/media_pipeline.dart';
import 'package:bookn_cp_app/services/section_content_service.dart';
import 'package:bookn_cp_app/services/section_service.dart';
import 'package:bookn_cp_app/services/biometric_auth_service.dart';
import 'features/admin_sections/data/datasources/section_images_remote_datasource.dart';
import 'features/admin_sections/data/datasources/property_in_section_images_remote_datasource.dart';
import 'features/admin_sections/data/datasources/unit_in_section_images_remote_datasource.dart';
import 'features/admin_sections/domain/repositories/section_images_repository.dart';
import 'features/admin_sections/data/repositories/section_images_repository_impl.dart';
import 'features/admin_sections/domain/usecases/section_images/usecases.dart';
import 'features/admin_sections/presentation/bloc/section_images/section_images_bloc.dart';
import 'features/admin_sections/presentation/bloc/section_images/section_images_event.dart';
import 'features/admin_sections/presentation/bloc/section_images/section_images_state.dart';
import 'features/admin_sections/domain/repositories/property_in_section_images_repository.dart';
import 'features/admin_sections/data/repositories/property_in_section_images_repository_impl.dart';
import 'features/admin_sections/domain/usecases/property_in_section_images/usecases.dart'
    as pis_uc;
import 'features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_bloc.dart';
import 'features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_event.dart';
import 'features/admin_sections/presentation/bloc/property_in_section_images/property_in_section_images_state.dart';
import 'features/admin_sections/domain/repositories/unit_in_section_images_repository.dart';
import 'features/admin_sections/data/repositories/unit_in_section_images_repository_impl.dart';
import 'features/admin_sections/domain/usecases/unit_in_section_images/usecases.dart'
    as uis_uc;
import 'features/admin_sections/presentation/bloc/unit_in_section_images/unit_in_section_images_bloc.dart';
import 'features/admin_sections/presentation/bloc/unit_in_section_images/unit_in_section_images_event.dart';
import 'features/admin_sections/presentation/bloc/unit_in_section_images/unit_in_section_images_state.dart';
import 'features/admin_sections/presentation/bloc/sections_list/sections_list_bloc.dart';
import 'features/admin_sections/presentation/bloc/section_form/section_form_bloc.dart';
import 'features/admin_sections/presentation/bloc/section_items/section_items_bloc.dart';
import 'features/admin_financial/presentation/bloc/accounts/accounts_bloc.dart';
import 'features/admin_financial/presentation/bloc/transactions/transactions_bloc.dart';
import 'features/admin_financial/presentation/bloc/financial_overview/financial_overview_bloc.dart';
import 'features/admin_financial/domain/repositories/financial_repository.dart';
import 'features/admin_financial/data/repositories/financial_repository_impl.dart';
import 'features/admin_financial/data/datasources/financial_remote_datasource.dart';

import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:io' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookn_cp_app/core/bloc/theme/theme_bloc.dart';

// Core
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';

// Services
import 'services/local_storage_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/deep_link_service.dart';
import 'services/websocket_service.dart';
import 'services/chat_sync_manager.dart';
import 'services/connectivity_service.dart';

// Admin Hub - Screen Search
import 'features/admin_hub/data/services/screen_search_service.dart';
// Helpers Feature
import 'features/helpers/data/datasources/helpers_remote_datasource.dart'
    as helpers_ds;
import 'features/helpers/data/repositories/helpers_repository_impl.dart'
    as helpers_repo_impl;
import 'features/helpers/domain/repositories/helpers_repository.dart'
    as helpers_repo;
import 'features/helpers/domain/usecases/search_users_usecase.dart'
    as helpers_uc_users;
import 'features/helpers/domain/usecases/search_properties_usecase.dart'
    as helpers_uc_props;
import 'features/helpers/domain/usecases/search_units_usecase.dart'
    as helpers_uc_units;
import 'features/helpers/domain/usecases/search_cities_usecase.dart'
    as helpers_uc_cities;
import 'features/helpers/domain/usecases/search_bookings_usecase.dart'
    as helpers_uc_bookings;

// Features - Settings
import 'features/settings/presentation/bloc/settings_bloc.dart' as st_bloc;
import 'features/settings/domain/repositories/settings_repository.dart'
    as st_repo;
import 'features/settings/data/repositories/settings_repository_impl.dart'
    as st_repo_impl;
import 'features/settings/data/datasources/settings_local_datasource.dart'
    as st_ds_local;
import 'features/settings/domain/usecases/get_settings_usecase.dart'
    as st_uc_get;
import 'features/settings/domain/usecases/update_language_usecase.dart'
    as st_uc_lang;
import 'features/settings/domain/usecases/update_theme_usecase.dart'
    as st_uc_theme;
import 'features/settings/domain/usecases/update_biometric_usecase.dart'
    as st_uc_bio;
import 'features/settings/domain/usecases/update_notification_settings_usecase.dart'
    as st_uc_notif;

// Features - Onboarding
import 'features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as onboarding_bloc;

// Features - Reference
import 'features/reference/presentation/bloc/reference_bloc.dart' as ref_bloc;
import 'features/reference/domain/repositories/reference_repository.dart'
    as ref_repo;
import 'features/reference/data/repositories/reference_repository_impl.dart'
    as ref_repo_impl;
import 'features/reference/data/datasources/reference_remote_datasource.dart'
    as ref_ds_remote;
import 'features/reference/data/datasources/reference_local_datasource.dart'
    as ref_ds_local;
import 'features/reference/domain/usecases/get_cities_usecase.dart'
    as ref_uc_cities;
import 'features/reference/domain/usecases/get_currencies_usecase.dart'
    as ref_uc_currencies;

// Features - Admin Currencies
import 'features/admin_currencies/presentation/bloc/currencies_bloc.dart'
    as ac_bloc;
import 'features/admin_currencies/domain/repositories/currencies_repository.dart'
    as ac_repo;
import 'features/admin_currencies/data/repositories/currencies_repository_impl.dart'
    as ac_repo_impl;
import 'features/admin_currencies/data/datasources/currencies_remote_datasource.dart'
    as ac_ds_remote;
import 'features/admin_currencies/data/datasources/currencies_local_datasource.dart'
    as ac_ds_local;
import 'features/admin_currencies/domain/usecases/get_currencies_usecase.dart'
    as ac_uc1;
import 'features/admin_currencies/domain/usecases/save_currencies_usecase.dart'
    as ac_uc2;
import 'features/admin_currencies/domain/usecases/delete_currency_usecase.dart'
    as ac_uc3;
import 'features/admin_currencies/domain/usecases/set_default_currency_usecase.dart'
    as ac_uc4;

// Features - Admin Cities
import 'features/admin_cities/presentation/bloc/cities_bloc.dart' as ci_bloc;
import 'features/admin_cities/domain/repositories/cities_repository.dart'
    as ci_repo;
import 'features/admin_cities/data/repositories/cities_repository_impl.dart'
    as ci_repo_impl;
import 'features/admin_cities/data/datasources/cities_remote_datasource.dart'
    as ci_ds_remote;
import 'features/admin_cities/data/datasources/cities_local_datasource.dart'
    as ci_ds_local;
import 'features/admin_cities/domain/usecases/get_cities_usecase.dart'
    as ci_uc1;
import 'features/admin_cities/domain/usecases/save_cities_usecase.dart'
    as ci_uc2;
import 'features/admin_cities/domain/usecases/create_city_usecase.dart'
    as ci_uc3;
import 'features/admin_cities/domain/usecases/update_city_usecase.dart'
    as ci_uc4;
import 'features/admin_cities/domain/usecases/delete_city_usecase.dart'
    as ci_uc5;
import 'features/admin_cities/domain/usecases/search_cities_usecase.dart'
    as ci_uc6;
import 'features/admin_cities/domain/usecases/get_cities_statistics_usecase.dart'
    as ci_uc7;
import 'features/admin_cities/domain/usecases/upload_city_image_usecase.dart'
    as ci_uc8;
import 'features/admin_cities/domain/usecases/delete_city_image_usecase.dart'
    as ci_uc9;

// Features - Admin Users
import 'features/admin_users/presentation/bloc/users_list/users_list_bloc.dart';
import 'features/admin_users/presentation/bloc/user_details/user_details_bloc.dart';
import 'features/admin_users/domain/repositories/users_repository.dart'
    as au_repo;
import 'features/admin_users/data/repositories/users_repository_impl.dart'
    as au_repo_impl;
import 'features/admin_users/data/datasources/users_remote_datasource.dart'
    as au_ds_remote;
import 'features/admin_users/data/datasources/users_local_datasource.dart'
    as au_ds_local;
import 'features/admin_users/domain/usecases/get_all_users_usecase.dart'
    as au_uc1;
import 'features/admin_users/domain/usecases/get_user_details_usecase.dart'
    as au_uc2;
import 'features/admin_users/domain/usecases/create_user_usecase.dart'
    as au_uc3;
import 'features/admin_users/domain/usecases/update_user_usecase.dart'
    as au_uc4;
import 'features/admin_users/domain/usecases/activate_user_usecase.dart'
    as au_uc5;
import 'features/admin_users/domain/usecases/deactivate_user_usecase.dart'
    as au_uc6;
import 'features/admin_users/domain/usecases/assign_role_usecase.dart'
    as au_uc7;
import 'features/admin_users/domain/usecases/get_user_lifetime_stats_usecase.dart'
    as au_uc8;

// Features - Auth
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/upload_user_image_usecase.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
// Features - Notifications
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/domain/usecases/get_notifications_usecase.dart'
    as notif_uc_get;
import 'features/notifications/domain/usecases/mark_as_read_usecase.dart'
    as notif_uc_mark;
import 'features/notifications/domain/usecases/dismiss_notification_usecase.dart'
    as notif_uc_dismiss;
import 'features/notifications/domain/usecases/update_notification_settings_usecase.dart'
    as notif_uc_update;
import 'features/notifications/domain/usecases/get_unread_count_usecase.dart'
    as notif_uc_unread;
import 'features/notifications/domain/usecases/get_notification_settings_usecase.dart'
    as notif_uc_get_settings;
import 'features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;
import 'features/notifications/data/repositories/notification_repository_impl.dart'
    as notif_repo_impl;
import 'features/notifications/data/datasources/notification_remote_datasource.dart'
    as notif_ds_remote;
import 'features/notifications/data/datasources/notification_local_datasource.dart'
    as notif_ds_local;

// Features - Notification Channels
import 'features/notification_channels/presentation/bloc/channels_bloc.dart';
import 'features/notification_channels/data/datasources/notification_channels_remote_datasource.dart';
import 'features/notification_channels/data/repositories/notification_channels_repository_impl.dart';
import 'features/notification_channels/domain/repositories/notification_channels_repository.dart';

// Features - Chat
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/datasources/chat_local_datasource.dart';
import 'features/chat/domain/usecases/get_conversations_usecase.dart';
import 'features/chat/domain/usecases/get_messages_usecase.dart';
import 'features/chat/domain/usecases/send_message_usecase.dart';
import 'features/chat/domain/usecases/create_conversation_usecase.dart';
import 'features/chat/domain/usecases/delete_conversation_usecase.dart';
import 'features/chat/domain/usecases/archive_conversation_usecase.dart';
import 'features/chat/domain/usecases/unarchive_conversation_usecase.dart';
import 'features/chat/domain/usecases/delete_message_usecase.dart';
import 'features/chat/domain/usecases/edit_message_usecase.dart';
import 'features/chat/domain/usecases/add_reaction_usecase.dart';
import 'features/chat/domain/usecases/remove_reaction_usecase.dart';
import 'features/chat/domain/usecases/mark_as_read_usecase.dart';
import 'features/chat/domain/usecases/upload_attachment_usecase.dart';
import 'features/chat/domain/usecases/search_chats_usecase.dart';
import 'features/chat/domain/usecases/get_available_users_usecase.dart';
import 'features/chat/domain/usecases/get_admin_users_usecase.dart';
import 'features/chat/domain/usecases/update_user_status_usecase.dart';
import 'features/chat/domain/usecases/get_chat_settings_usecase.dart';
import 'features/chat/domain/usecases/update_chat_settings_usecase.dart';
import 'features/chat/domain/usecases/send_typing_indicator_usecase.dart';

// Features - Admin Units
import 'features/admin_units/presentation/bloc/units_list/units_list_bloc.dart';
import 'features/admin_units/presentation/bloc/unit_form/unit_form_bloc.dart';
import 'features/admin_units/presentation/bloc/unit_details/unit_details_bloc.dart';
import 'features/admin_units/domain/repositories/units_repository.dart';
import 'features/admin_units/data/repositories/units_repository_impl.dart';
import 'features/admin_units/data/datasources/units_remote_datasource.dart';
import 'features/admin_units/data/datasources/units_local_datasource.dart';
import 'features/admin_units/domain/usecases/get_units_usecase.dart';
import 'features/admin_units/domain/usecases/get_unit_details_usecase.dart';
import 'features/admin_units/domain/usecases/create_unit_usecase.dart';
import 'features/admin_units/domain/usecases/update_unit_usecase.dart';
import 'features/admin_units/domain/usecases/delete_unit_usecase.dart';
import 'features/admin_units/domain/usecases/get_unit_types_by_property_usecase.dart';
import 'features/admin_units/domain/usecases/get_unit_fields_usecase.dart';
import 'features/admin_units/domain/usecases/assign_unit_to_sections_usecase.dart';

// Features - Property Types
import 'features/property_types/presentation/bloc/property_types/property_types_bloc.dart';
import 'features/property_types/presentation/bloc/unit_types/unit_types_bloc.dart';
import 'features/property_types/presentation/bloc/unit_type_fields/unit_type_fields_bloc.dart';
import 'features/property_types/domain/repositories/property_types_repository.dart'
    as pt_domain;
import 'features/property_types/domain/repositories/unit_types_repository.dart'
    as ut_domain;
import 'features/property_types/domain/repositories/unit_type_fields_repository.dart'
    as utf_domain;
import 'features/property_types/data/repositories/property_types_repository_impl.dart'
    as pt_data;
import 'features/property_types/data/repositories/unit_types_repository_impl.dart'
    as ut_data;
import 'features/property_types/data/repositories/unit_type_fields_repository_impl.dart'
    as utf_data;
import 'features/property_types/data/datasources/property_types_remote_datasource.dart'
    as pt_ds;
import 'features/property_types/data/datasources/unit_types_remote_datasource.dart'
    as ut_ds;
import 'features/property_types/data/datasources/unit_type_fields_remote_datasource.dart'
    as utf_ds;
import 'features/property_types/domain/usecases/property_types/get_all_property_types_usecase.dart'
    as pt_uc;
import 'features/property_types/domain/usecases/property_types/create_property_type_usecase.dart'
    as pt_uc3;
import 'features/property_types/domain/usecases/property_types/update_property_type_usecase.dart'
    as pt_uc4;
import 'features/property_types/domain/usecases/property_types/delete_property_type_usecase.dart'
    as pt_uc5;
import 'features/property_types/domain/usecases/unit_types/get_unit_types_by_property_usecase.dart'
    as ut_uc1;
import 'features/property_types/domain/usecases/unit_types/create_unit_type_usecase.dart'
    as ut_uc2;
import 'features/property_types/domain/usecases/unit_types/update_unit_type_usecase.dart'
    as ut_uc3;
import 'features/property_types/domain/usecases/unit_types/delete_unit_type_usecase.dart'
    as ut_uc4;
import 'features/property_types/domain/usecases/fields/get_fields_by_unit_type_usecase.dart'
    as utf_uc1;
import 'features/property_types/domain/usecases/fields/create_field_usecase.dart'
    as utf_uc2;
import 'features/property_types/domain/usecases/fields/update_field_usecase.dart'
    as utf_uc3;
import 'features/property_types/domain/usecases/fields/delete_field_usecase.dart'
    as utf_uc4;

// Features - Admin Services
import 'features/admin_services/presentation/bloc/services_bloc.dart';
import 'features/admin_services/data/datasources/services_remote_datasource.dart';
import 'features/admin_services/data/repositories/services_repository_impl.dart';
import 'features/admin_services/domain/repositories/services_repository.dart';
import 'features/admin_services/domain/usecases/create_service_usecase.dart'
    as as_uc1;
import 'features/admin_services/domain/usecases/update_service_usecase.dart'
    as as_uc2;
import 'features/admin_services/domain/usecases/delete_service_usecase.dart'
    as as_uc3;
import 'features/admin_services/domain/usecases/get_services_by_property_usecase.dart'
    as as_uc4;
import 'features/admin_services/domain/usecases/get_service_details_usecase.dart'
    as as_uc5;
import 'features/admin_services/domain/usecases/get_services_by_type_usecase.dart'
    as as_uc6;

// Features - Admin Reviews
import 'features/admin_reviews/presentation/bloc/reviews_list/reviews_list_bloc.dart'
    as ar_list_bloc;
import 'features/admin_reviews/presentation/bloc/review_details/review_details_bloc.dart'
    as ar_details_bloc;
import 'features/admin_reviews/presentation/bloc/review_response/review_response_bloc.dart'
    as ar_resp_bloc;
import 'features/admin_reviews/data/datasources/reviews_remote_datasource.dart'
    as ar_ds_remote;
import 'features/admin_reviews/data/datasources/reviews_local_datasource.dart'
    as ar_ds_local;
import 'features/admin_reviews/data/repositories/reviews_repository_impl.dart'
    as ar_repo_impl;
import 'features/admin_reviews/domain/repositories/reviews_repository.dart'
    as ar_repo;
import 'features/admin_reviews/domain/usecases/get_all_reviews_usecase.dart'
    as ar_uc1;
import 'features/admin_reviews/domain/usecases/approve_review_usecase.dart'
    as ar_uc2;
import 'features/admin_reviews/domain/usecases/delete_review_usecase.dart'
    as ar_uc3;
import 'features/admin_reviews/domain/usecases/get_review_details_usecase.dart'
    as ar_uc4;
import 'features/admin_reviews/domain/usecases/get_review_responses_usecase.dart'
    as ar_uc5;
import 'features/admin_reviews/domain/usecases/respond_to_review_usecase.dart'
    as ar_uc6;
import 'features/admin_reviews/domain/usecases/delete_review_response_usecase.dart'
    as ar_uc7;

// Features - Admin Audit Logs
import 'features/admin_audit_logs/presentation/bloc/audit_logs_bloc.dart';
import 'features/admin_audit_logs/data/datasources/audit_logs_remote_datasource.dart'
    as al_ds_remote;
import 'features/admin_audit_logs/data/datasources/audit_logs_local_datasource.dart'
    as al_ds_local;
import 'features/admin_audit_logs/data/repositories/audit_logs_repository_impl.dart'
    as al_repo_impl;
import 'features/admin_audit_logs/domain/repositories/audit_logs_repository.dart'
    as al_repo;
import 'features/admin_audit_logs/domain/usecases/get_audit_logs_usecase.dart'
    as al_uc_get;
import 'features/admin_audit_logs/domain/usecases/export_audit_logs_usecase.dart'
    as al_uc_export;
import 'features/admin_audit_logs/domain/usecases/get_customer_activity_logs_usecase.dart'
    as al_uc_get_cust;
import 'features/admin_audit_logs/domain/usecases/get_property_activity_logs_usecase.dart'
    as al_uc_get_prop;
import 'features/admin_audit_logs/domain/usecases/get_admin_activity_logs_usecase.dart'
    as al_uc_get_admin;

// Features - Admin Amenities (standalone)
import 'features/admin_amenities/presentation/bloc/amenities_bloc.dart'
    as aa_bloc;
import 'features/admin_amenities/data/datasources/amenities_remote_datasource.dart'
    as aa_ds_remote;
import 'features/admin_amenities/data/repositories/amenities_repository_impl.dart'
    as aa_repo_impl;
import 'features/admin_amenities/domain/repositories/amenities_repository.dart'
    as aa_repo;
import 'features/admin_amenities/domain/usecases/create_amenity_usecase.dart'
    as aa_uc1;
import 'features/admin_amenities/domain/usecases/update_amenity_usecase.dart'
    as aa_uc2;
import 'features/admin_amenities/domain/usecases/delete_amenity_usecase.dart'
    as aa_uc3;
import 'features/admin_amenities/domain/usecases/get_all_amenities_usecase.dart'
    as aa_uc4;
import 'features/admin_amenities/domain/usecases/assign_amenity_to_property_usecase.dart'
    as aa_uc5;

// Features - Admin Policies (standalone)
import 'features/admin_policies/presentation/bloc/policies_bloc.dart'
    as apo_bloc;
import 'features/admin_policies/data/datasources/policies_remote_datasource.dart'
    as apo_ds_remote;
import 'features/admin_policies/data/datasources/policies_local_datasource.dart'
    as apo_ds_local;
import 'features/admin_policies/data/repositories/policies_repository_impl.dart'
    as apo_repo_impl;
import 'features/admin_policies/domain/repositories/policies_repository.dart'
    as apo_repo;
import 'features/admin_policies/domain/usecases/create_policy_usecase.dart'
    as apo_uc1;
import 'features/admin_policies/domain/usecases/update_policy_usecase.dart'
    as apo_uc2;
import 'features/admin_policies/domain/usecases/delete_policy_usecase.dart'
    as apo_uc3;
import 'features/admin_policies/domain/usecases/get_all_policies_usecase.dart'
    as apo_uc4;
import 'features/admin_policies/domain/usecases/get_policy_by_id_usecase.dart'
    as apo_uc5;
import 'features/admin_policies/domain/usecases/get_policies_by_property_usecase.dart'
    as apo_uc6;
import 'features/admin_policies/domain/usecases/get_policies_by_type_usecase.dart'
    as apo_uc7;
import 'features/admin_policies/domain/usecases/toggle_policy_status_usecase.dart'
    as apo_uc8;

// Features - Admin Properties
import 'features/admin_properties/presentation/bloc/properties/properties_bloc.dart'
    as ap_bloc;
import 'features/admin_properties/presentation/bloc/amenities/amenities_bloc.dart'
    as ap_am_bloc;
import 'features/admin_properties/presentation/bloc/policies/policies_bloc.dart'
    as ap_po_bloc;
import 'features/admin_properties/presentation/bloc/property_types/property_types_bloc.dart'
    as ap_pt_bloc;
import 'features/admin_properties/domain/repositories/properties_repository.dart'
    as ap_repo;
import 'features/admin_properties/domain/repositories/amenities_repository.dart'
    as ap_am_repo;
import 'features/admin_properties/domain/repositories/policies_repository.dart'
    as ap_po_repo;
import 'features/admin_properties/domain/repositories/property_types_repository.dart'
    as ap_pt_repo;
import 'features/admin_properties/data/repositories/properties_repository_impl.dart'
    as ap_repo_impl;
import 'features/admin_properties/data/repositories/amenities_repository_impl.dart'
    as ap_am_repo_impl;
import 'features/admin_properties/data/repositories/policies_repository_impl.dart'
    as ap_po_repo_impl;
import 'features/admin_properties/data/repositories/property_types_repository_impl.dart'
    as ap_pt_repo_impl;
import 'features/admin_properties/data/datasources/properties_remote_datasource.dart'
    as ap_ds_prop_remote;
import 'features/admin_properties/data/datasources/properties_local_datasource.dart'
    as ap_ds_prop_local;
import 'features/admin_properties/data/datasources/amenities_remote_datasource.dart'
    as ap_ds_am_remote;
import 'features/admin_properties/data/datasources/policies_remote_datasource.dart'
    as ap_ds_po_remote;
import 'features/admin_properties/data/datasources/property_types_remote_datasource.dart'
    as ap_ds_pt_remote;
import 'features/admin_properties/domain/usecases/properties/get_all_properties_usecase.dart'
    as ap_uc_prop1;
import 'features/admin_properties/domain/usecases/properties/create_property_usecase.dart'
    as ap_uc_prop2;
import 'features/admin_properties/domain/usecases/properties/update_property_usecase.dart'
    as ap_uc_prop3;
import 'features/admin_properties/domain/usecases/properties/owner_update_property_usecase.dart'
    as ap_uc_prop_owner_update;
import 'features/admin_properties/domain/usecases/properties/get_property_details_public_usecase.dart'
    as ap_uc_prop_public_details;
import 'features/admin_properties/domain/usecases/properties/delete_property_usecase.dart'
    as ap_uc_prop4;
import 'features/admin_properties/domain/usecases/properties/approve_property_usecase.dart'
    as ap_uc_prop5;
import 'features/admin_properties/domain/usecases/properties/reject_property_usecase.dart'
    as ap_uc_prop6;
import 'features/admin_properties/domain/usecases/properties/get_property_details_usecase.dart'
    as ap_uc_prop7;
import 'features/admin_properties/domain/usecases/amenities/get_amenities_usecase.dart'
    as ap_uc_am1;
import 'features/admin_properties/domain/usecases/amenities/create_amenity_usecase.dart'
    as ap_uc_am2;
import 'features/admin_properties/domain/usecases/amenities/update_amenity_usecase.dart'
    as ap_uc_am3;
import 'features/admin_properties/domain/usecases/amenities/delete_amenity_usecase.dart'
    as ap_uc_am4;
import 'features/admin_properties/domain/usecases/amenities/assign_amenity_to_property_usecase.dart'
    as ap_uc_am5;
import 'features/admin_properties/domain/usecases/amenities/unassign_amenity_from_property_usecase.dart'
    as ap_uc_am6;
import 'features/admin_properties/domain/usecases/policies/get_policies_usecase.dart'
    as ap_uc_po1;
import 'features/admin_properties/domain/usecases/policies/create_policy_usecase.dart'
    as ap_uc_po2;
import 'features/admin_properties/domain/usecases/policies/update_policy_usecase.dart'
    as ap_uc_po3;
import 'features/admin_properties/domain/usecases/policies/delete_policy_usecase.dart'
    as ap_uc_po4;
import 'features/admin_properties/domain/usecases/property_types/get_property_types_usecase.dart'
    as ap_uc_pt1;
import 'features/admin_properties/domain/usecases/property_types/create_property_type_usecase.dart'
    as ap_uc_pt2;
import 'features/admin_properties/domain/usecases/property_types/update_property_type_usecase.dart'
    as ap_uc_pt3;
import 'features/admin_properties/domain/usecases/property_types/delete_property_type_usecase.dart'
    as ap_uc_pt4;

// Features - Admin Availability & Pricing
import 'features/admin_availability_pricing/presentation/bloc/availability/availability_bloc.dart';
import 'features/admin_availability_pricing/presentation/bloc/pricing/pricing_bloc.dart';
import 'features/admin_availability_pricing/domain/repositories/availability_repository.dart'
    as aap_av_repo;
import 'features/admin_availability_pricing/domain/repositories/pricing_repository.dart'
    as aap_pr_repo;
import 'features/admin_availability_pricing/data/repositories/availability_repository_impl.dart'
    as aap_av_repo_impl;
import 'features/admin_availability_pricing/data/repositories/pricing_repository_impl.dart'
    as aap_pr_repo_impl;
import 'features/admin_availability_pricing/data/datasources/availability_remote_datasource.dart'
    as aap_av_ds_remote;
import 'features/admin_availability_pricing/data/datasources/availability_local_datasource.dart'
    as aap_av_ds_local;
import 'features/admin_availability_pricing/data/datasources/pricing_remote_datasource.dart'
    as aap_pr_ds_remote;
import 'features/admin_availability_pricing/domain/usecases/availability/get_monthly_availability_usecase.dart'
    as aap_av_uc_get;
import 'features/admin_availability_pricing/domain/usecases/availability/update_availability_usecase.dart'
    as aap_av_uc_update;
import 'features/admin_availability_pricing/domain/usecases/availability/bulk_update_availability_usecase.dart'
    as aap_av_uc_bulk;
import 'features/admin_availability_pricing/domain/usecases/availability/check_availability_usecase.dart'
    as aap_av_uc_check;
import 'features/admin_availability_pricing/domain/usecases/availability/clone_availability_usecase.dart'
    as aap_av_uc_clone;
import 'features/admin_availability_pricing/domain/usecases/availability/delete_availability_usecase.dart'
    as aap_av_uc_delete;
import 'features/admin_availability_pricing/domain/usecases/pricing/get_monthly_pricing_usecase.dart'
    as aap_pr_uc_get;
import 'features/admin_availability_pricing/domain/usecases/pricing/update_pricing_usecase.dart'
    as aap_pr_uc_update;
import 'features/admin_availability_pricing/domain/usecases/pricing/bulk_update_pricing_usecase.dart'
    as aap_pr_uc_bulk;
import 'features/admin_availability_pricing/domain/usecases/pricing/copy_pricing_usecase.dart'
    as aap_pr_uc_copy;
import 'features/admin_availability_pricing/domain/usecases/pricing/delete_pricing_usecase.dart'
    as aap_pr_uc_delete;
import 'features/admin_availability_pricing/domain/usecases/pricing/apply_seasonal_pricing_usecase.dart'
    as aap_pr_uc_apply;

// Features - Admin Bookings (DI for repository + upcoming bookings use case)
import 'features/admin_bookings/domain/repositories/bookings_repository.dart'
    as ab_repo;
import 'features/admin_bookings/data/repositories/bookings_repository_impl.dart'
    as ab_repo_impl;
import 'features/admin_bookings/data/datasources/bookings_remote_datasource.dart'
    as ab_ds_remote;
import 'features/admin_bookings/data/datasources/bookings_local_datasource.dart'
    as ab_ds_local;
import 'features/admin_bookings/domain/usecases/bookings/get_upcoming_bookings_usecase.dart'
    as ab_uc_upcoming;
// Admin Bookings - Bookings use cases
import 'features/admin_bookings/domain/usecases/bookings/cancel_booking_usecase.dart'
    as ab_uc_cancel;
import 'features/admin_bookings/domain/usecases/bookings/update_booking_usecase.dart'
    as ab_uc_update;
import 'features/admin_bookings/domain/usecases/bookings/confirm_booking_usecase.dart'
    as ab_uc_confirm;
import 'features/admin_bookings/domain/usecases/bookings/check_in_usecase.dart'
    as ab_uc_checkin;
import 'features/admin_bookings/domain/usecases/bookings/check_out_usecase.dart'
    as ab_uc_checkout;
import 'features/admin_bookings/domain/usecases/bookings/get_booking_by_id_usecase.dart'
    as ab_uc_get_by_id;
import 'features/admin_bookings/domain/usecases/bookings/get_bookings_by_date_range_usecase.dart'
    as ab_uc_get_by_range;
import 'features/admin_bookings/domain/usecases/bookings/get_bookings_by_property_usecase.dart'
    as ab_uc_get_by_property;
import 'features/admin_bookings/domain/usecases/bookings/get_bookings_by_status_usecase.dart'
    as ab_uc_get_by_status;
import 'features/admin_bookings/domain/usecases/bookings/get_bookings_by_user_usecase.dart'
    as ab_uc_get_by_user;
import 'features/admin_bookings/domain/usecases/bookings/get_bookings_by_unit_usecase.dart'
    as ab_uc_get_by_unit;
import 'features/admin_bookings/domain/usecases/bookings/complete_booking_usecase.dart'
    as ab_uc_complete;
// Admin Bookings - Services use cases
import 'features/admin_bookings/domain/usecases/services/add_service_to_booking_usecase.dart'
    as ab_uc_add_service;
import 'features/admin_bookings/domain/usecases/services/remove_service_from_booking_usecase.dart'
    as ab_uc_remove_service;
import 'features/admin_bookings/domain/usecases/services/get_booking_services_usecase.dart'
    as ab_uc_get_services;
import 'features/admin_bookings/domain/usecases/register_booking_payment.dart'
    as ab_uc_register_payment;
// Admin Bookings - Reports use cases
import 'features/admin_bookings/domain/usecases/reports/get_booking_report_usecase.dart'
    as ab_uc_report;
import 'features/admin_bookings/domain/usecases/reports/get_booking_trends_usecase.dart'
    as ab_uc_trends;
import 'features/admin_bookings/domain/usecases/reports/get_booking_window_analysis_usecase.dart'
    as ab_uc_window;
// Admin Bookings - Blocs
import 'features/admin_bookings/presentation/bloc/bookings_list/bookings_list_bloc.dart'
    as ab_list_bloc;
import 'features/admin_bookings/presentation/bloc/booking_details/booking_details_bloc.dart'
    as ab_details_bloc;
import 'features/admin_bookings/presentation/bloc/booking_calendar/booking_calendar_bloc.dart'
    as ab_cal_bloc;
import 'features/admin_bookings/presentation/bloc/booking_analytics/booking_analytics_bloc.dart'
    as ab_an_bloc;
import 'features/admin_bookings/presentation/bloc/register_payment/register_payment_bloc.dart'
    as ab_register_payment_bloc;

// Payments feature imports
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_bloc.dart'
    as pay_list_bloc;
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_details/payment_details_bloc.dart'
    as pay_details_bloc;
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_refund/payment_refund_bloc.dart'
    as pay_refund_bloc;
import 'features/admin_payments/domain/repositories/payments_repository.dart'
    as pay_repo;
import 'features/admin_payments/data/repositories/payments_repository_impl.dart'
    as pay_repo_impl;
import 'features/admin_payments/data/datasources/payments_remote_datasource.dart'
    as pay_ds_remote;
import 'features/admin_payments/data/datasources/payments_local_datasource.dart'
    as pay_ds_local;
import 'features/admin_payments/domain/usecases/payments/get_all_payments_usecase.dart'
    as pay_uc_get_all;
import 'features/admin_payments/domain/usecases/payments/get_payment_by_id_usecase.dart'
    as pay_uc_get_by_id;
import 'features/admin_payments/domain/usecases/payments/refund_payment_usecase.dart'
    as pay_uc_refund;
import 'features/admin_payments/domain/usecases/payments/void_payment_usecase.dart'
    as pay_uc_void;
import 'features/admin_payments/domain/usecases/payments/update_payment_status_usecase.dart'
    as pay_uc_update_status;
import 'features/admin_payments/domain/usecases/payments/process_payment_usecase.dart'
    as pay_uc_process;
import 'features/admin_payments/domain/usecases/queries/get_payments_by_booking_usecase.dart'
    as pay_uc_by_booking;
import 'features/admin_payments/domain/usecases/queries/get_payments_by_status_usecase.dart'
    as pay_uc_by_status;
import 'features/admin_payments/domain/usecases/queries/get_payments_by_user_usecase.dart'
    as pay_uc_by_user;
import 'features/admin_payments/domain/usecases/queries/get_payments_by_property_usecase.dart'
    as pay_uc_by_property;
import 'features/admin_payments/domain/usecases/queries/get_payments_by_method_usecase.dart'
    as pay_uc_by_method;
import 'features/admin_payments/domain/usecases/analytics/get_payment_analytics_usecase.dart'
    as pay_uc_analytics;
import 'features/admin_payments/domain/usecases/analytics/get_revenue_report_usecase.dart'
    as pay_uc_revenue;
import 'features/admin_payments/domain/usecases/analytics/get_payment_trends_usecase.dart'
    as pay_uc_trends;
import 'features/admin_payments/domain/usecases/analytics/get_refund_statistics_usecase.dart'
    as pay_uc_refund_stats;
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_analytics/payment_analytics_bloc.dart'
    as pay_an_bloc;
import 'package:bookn_cp_app/features/auth/verification/bloc/email_verification_bloc.dart';
// Admin Notifications
import 'features/admin_notifications/presentation/bloc/admin_notifications_bloc.dart'
    as an_bloc;
import 'features/admin_notifications/domain/repositories/admin_notifications_repository.dart'
    as an_repo;
import 'features/admin_notifications/data/repositories/admin_notifications_repository_impl.dart'
    as an_repo_impl;
import 'features/admin_notifications/data/datasources/admin_notifications_remote_datasource.dart'
    as an_ds_remote;
import 'features/admin_notifications/domain/usecases/create_notification_usecase.dart'
    as an_uc_create;
import 'features/admin_notifications/domain/usecases/broadcast_notification_usecase.dart'
    as an_uc_broadcast;
import 'features/admin_notifications/domain/usecases/delete_notification_usecase.dart'
    as an_uc_delete;
import 'features/admin_notifications/domain/usecases/resend_notification_usecase.dart'
    as an_uc_resend;
import 'features/admin_notifications/domain/usecases/get_system_notifications_usecase.dart'
    as an_uc_get_system;
import 'features/admin_notifications/domain/usecases/get_user_notifications_usecase.dart'
    as an_uc_get_user;
import 'features/admin_notifications/domain/usecases/get_notifications_stats_usecase.dart'
    as an_uc_stats;

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  _initAuth();
  // Features - Auth Verification
  _initAuthVerification();

  // Features - Chat
  _initChat();

  // Features - Admin Users
  _initAdminUsers();

  // Features - Admin Units
  _initAdminUnits();

  // Features - Property Types
  _initPropertyTypes();

  // Features - Admin Properties
  _initAdminProperties();

  // Features - Admin Services
  _initAdminServices();

  // Features - Admin Reviews
  _initAdminReviews();

  // Features - Admin Audit Logs
  _initAdminAuditLogs();

  // Features - Admin Amenities (standalone)
  _initAdminAmenities();

  // Features - Admin Policies (standalone)
  _initAdminPolicies();

  // Features - Admin Currencies
  _initAdminCurrencies();

  // Features - Admin Cities
  _initAdminCities();

  // Features - Admin Availability & Pricing
  _initAdminAvailabilityPricing();

  // Features - Helpers (search/filter facades)
  _initHelpers();

  // Features - Settings
  _initSettings();

  // Features - Notifications
  _initNotifications();
  // Features - Notification Channels
  _initNotificationChannels();

  // Features - Reference
  _initReference();

  // Features - Onboarding
  _initOnboarding();

  // Features - Admin Bookings (repository + use cases)
  _initAdminBookings();

  // Features - Admin Payments
  _initAdminPayments();

  // Features - Admin Sections
  _initAdminSections();

  // Features - Admin Notifications
  _initAdminNotifications();

  // Features - Admin Financial
  _initAdminFinancial();

  // Theme
  _initTheme();

  // Core
  _initCore();

  // External
  await _initExternal();
}

// Features - Notifications
void _initNotifications() {
  // Bloc
  sl.registerFactory(() => NotificationBloc(
        getNotificationsUseCase: sl<notif_uc_get.GetNotificationsUseCase>(),
        markAsReadUseCase: sl<notif_uc_mark.MarkAsReadUseCase>(),
        dismissNotificationUseCase:
            sl<notif_uc_dismiss.DismissNotificationUseCase>(),
        updateNotificationSettingsUseCase:
            sl<notif_uc_update.UpdateNotificationSettingsUseCase>(),
        getUnreadCountUseCase: sl<notif_uc_unread.GetUnreadCountUseCase>(),
        getNotificationSettingsUseCase:
            sl<notif_uc_get_settings.GetNotificationSettingsUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<notif_uc_get.GetNotificationsUseCase>(
      () => notif_uc_get.GetNotificationsUseCase(sl()));
  sl.registerLazySingleton<notif_uc_mark.MarkAsReadUseCase>(
      () => notif_uc_mark.MarkAsReadUseCase(sl()));
  sl.registerLazySingleton<notif_uc_dismiss.DismissNotificationUseCase>(
      () => notif_uc_dismiss.DismissNotificationUseCase(sl()));
  sl.registerLazySingleton<notif_uc_update.UpdateNotificationSettingsUseCase>(
      () => notif_uc_update.UpdateNotificationSettingsUseCase(sl()));
  sl.registerLazySingleton<notif_uc_unread.GetUnreadCountUseCase>(
      () => notif_uc_unread.GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton<
          notif_uc_get_settings.GetNotificationSettingsUseCase>(
      () => notif_uc_get_settings.GetNotificationSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<notif_repo.NotificationRepository>(
    () => notif_repo_impl.NotificationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<notif_ds_remote.NotificationRemoteDataSource>(
    () => notif_ds_remote.NotificationRemoteDataSourceImpl(
      apiClient: sl(),
      localStorage: sl(),
      authLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<notif_ds_local.NotificationLocalDataSource>(
    () => notif_ds_local.NotificationLocalDataSourceImpl(localStorage: sl()),
  );
}

void _initSettings() {
  // Bloc
  sl.registerFactory(() => st_bloc.SettingsBloc(
        getSettingsUseCase: sl<st_uc_get.GetSettingsUseCase>(),
        updateLanguageUseCase: sl<st_uc_lang.UpdateLanguageUseCase>(),
        updateThemeUseCase: sl<st_uc_theme.UpdateThemeUseCase>(),
        updateNotificationSettingsUseCase:
            sl<st_uc_notif.UpdateNotificationSettingsUseCase>(),
        localDataSource: sl(),
        biometricAuthService: sl(),
        updateBiometricUseCase: sl<st_uc_bio.UpdateBiometricUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<st_uc_get.GetSettingsUseCase>(
      () => st_uc_get.GetSettingsUseCase(sl()));
  sl.registerLazySingleton<st_uc_lang.UpdateLanguageUseCase>(
      () => st_uc_lang.UpdateLanguageUseCase(sl()));
  sl.registerLazySingleton<st_uc_theme.UpdateThemeUseCase>(
      () => st_uc_theme.UpdateThemeUseCase(sl()));
  sl.registerLazySingleton<st_uc_bio.UpdateBiometricUseCase>(
      () => st_uc_bio.UpdateBiometricUseCase(sl()));
  sl.registerLazySingleton<st_uc_notif.UpdateNotificationSettingsUseCase>(
      () => st_uc_notif.UpdateNotificationSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<st_repo.SettingsRepository>(
      () => st_repo_impl.SettingsRepositoryImpl(localDataSource: sl()));

  // Data source
  sl.registerLazySingleton<st_ds_local.SettingsLocalDataSource>(
      () => st_ds_local.SettingsLocalDataSourceImpl(localStorage: sl()));
}

void _initAuth() {
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      resetPasswordUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      getCurrentUserUseCase: sl(),
      updateProfileUseCase: sl(),
      uploadUserImageUseCase: sl(),
      changePasswordUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadUserImageUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

void _initAuthVerification() {
  // Bloc
  sl.registerFactory(() => EmailVerificationBloc(
        authRepository: sl(),
      ));
}

void _initChat() {
  // Bloc
  sl.registerFactory(() {
    final bloc = ChatBloc(
      getConversationsUseCase: sl(),
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      createConversationUseCase: sl(),
      deleteConversationUseCase: sl(),
      archiveConversationUseCase: sl(),
      unarchiveConversationUseCase: sl(),
      deleteMessageUseCase: sl(),
      editMessageUseCase: sl(),
      addReactionUseCase: sl(),
      removeReactionUseCase: sl(),
      markMessagesAsReadUseCase: sl(),
      uploadAttachmentUseCase: sl(),
      searchChatsUseCase: sl(),
      getAvailableUsersUseCase: sl(),
      updateUserStatusUseCase: sl(),
      getChatSettingsUseCase: sl(),
      updateChatSettingsUseCase: sl(),
      sendTypingIndicatorUseCase: sl(),
      getCurrentUserUseCase: sl(),
      webSocketService: sl(),
      mediaPipeline: sl(),
      getAdminUsersUseCase: sl(),
    );
    // Deliver FCM chat events directly to ChatBloc when available
    try {
      sl<NotificationService>().bindChatEventSink((event) => bloc.add(event));
    } catch (_) {}
    bloc.add(const InitializeChatEvent());
    return bloc;
  });

  // Use cases
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerLazySingleton(() => ArchiveConversationUseCase(sl()));
  sl.registerLazySingleton(() => UnarchiveConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMessageUseCase(sl()));
  sl.registerLazySingleton(() => EditMessageUseCase(sl()));
  sl.registerLazySingleton(() => AddReactionUseCase(sl()));
  sl.registerLazySingleton(() => RemoveReactionUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => UploadAttachmentUseCase(sl()));
  sl.registerLazySingleton(() => SearchChatsUseCase(sl()));
  sl.registerLazySingleton(() => GetAvailableUsersUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetChatSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateChatSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SendTypingIndicatorUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(),
  );

  // WebSocket Service
  sl.registerLazySingleton(() => ChatWebSocketService(
        authLocalDataSource: sl(),
        remoteDataSource: sl(),
      ));

  // Chat Sync Manager
  sl.registerLazySingleton(() => ChatSyncManager(
        repository: sl(),
        local: sl(),
        connectivity: sl(),
        ws: sl(),
      ));
}

void _initAdminUnits() {
  // Blocs
  sl.registerFactory(() => UnitsListBloc(
        getUnitsUseCase: sl(),
        deleteUnitUseCase: sl(),
      ));
  sl.registerFactory(() => UnitFormBloc(
        createUnitUseCase: sl(),
        updateUnitUseCase: sl(),
        getUnitTypesByPropertyUseCase: sl(),
        getUnitFieldsUseCase: sl(),
      ));
  sl.registerFactory(() => UnitDetailsBloc(
        getUnitDetailsUseCase: sl(),
        deleteUnitUseCase: sl(),
        assignUnitToSectionsUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetUnitsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnitDetailsUseCase(sl()));
  sl.registerLazySingleton(() => CreateUnitUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUnitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUnitUseCase(sl()));
  sl.registerLazySingleton(() => GetUnitTypesByPropertyUseCase(sl()));
  sl.registerLazySingleton(() => GetUnitFieldsUseCase(sl()));
  sl.registerLazySingleton(() => AssignUnitToSectionsUseCase(sl()));

  sl.registerLazySingleton(() => UploadUnitImageUseCase(sl()));
  sl.registerLazySingleton(() => GetUnitImagesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUnitImageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUnitImageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMultipleUnitImagesUseCase(sl()));
  sl.registerLazySingleton(() => ReorderUnitImagesUseCase(sl()));
  sl.registerLazySingleton(() => SetPrimaryUnitImageUseCase(sl()));
  sl.registerLazySingleton(() => UploadMultipleUnitImagesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<UnitsRepository>(() => UnitsRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<UnitsRemoteDataSource>(
      () => UnitsRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<UnitsLocalDataSource>(
      () => UnitsLocalDataSourceImpl(sharedPreferences: sl()));

  // Unit Images Repository
  sl.registerLazySingleton<UnitImagesRepository>(
    () => UnitImagesRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Unit Images Data Sources
  sl.registerLazySingleton<UnitImagesRemoteDataSource>(
    () => UnitImagesRemoteDataSourceImpl(apiClient: sl()),
  );

  // Unit Images BLoC
  sl.registerFactory(
    () => UnitImagesBloc(
      uploadUnitImage: sl(),
      uploadMultipleImages: sl(),
      getUnitImages: sl(),
      updateUnitImage: sl(),
      deleteUnitImage: sl(),
      deleteMultipleImages: sl(),
      reorderImages: sl(),
      setPrimaryImage: sl(),
    ),
  );
}

void _initPropertyTypes() {
  // Blocs
  sl.registerFactory(() => PropertyTypesBloc(
        getAllPropertyTypes: sl<pt_uc.GetAllPropertyTypesUseCase>(),
        createPropertyType: sl<pt_uc3.CreatePropertyTypeUseCase>(),
        updatePropertyType: sl<pt_uc4.UpdatePropertyTypeUseCase>(),
        deletePropertyType: sl<pt_uc5.DeletePropertyTypeUseCase>(),
      ));
  sl.registerFactory(() => UnitTypesBloc(
        getUnitTypesByProperty: sl<ut_uc1.GetUnitTypesByPropertyUseCase>(),
        createUnitType: sl<ut_uc2.CreateUnitTypeUseCase>(),
        updateUnitType: sl<ut_uc3.UpdateUnitTypeUseCase>(),
        deleteUnitType: sl<ut_uc4.DeleteUnitTypeUseCase>(),
      ));
  sl.registerFactory(() => UnitTypeFieldsBloc(
        getFieldsByUnitType: sl<utf_uc1.GetFieldsByUnitTypeUseCase>(),
        createField: sl<utf_uc2.CreateFieldUseCase>(),
        updateField: sl<utf_uc3.UpdateFieldUseCase>(),
        deleteField: sl<utf_uc4.DeleteFieldUseCase>(),
      ));

  // Use cases - property types
  sl.registerLazySingleton<pt_uc.GetAllPropertyTypesUseCase>(
      () => pt_uc.GetAllPropertyTypesUseCase(sl()));
  sl.registerLazySingleton<pt_uc3.CreatePropertyTypeUseCase>(
      () => pt_uc3.CreatePropertyTypeUseCase(sl()));
  sl.registerLazySingleton<pt_uc4.UpdatePropertyTypeUseCase>(
      () => pt_uc4.UpdatePropertyTypeUseCase(sl()));
  sl.registerLazySingleton<pt_uc5.DeletePropertyTypeUseCase>(
      () => pt_uc5.DeletePropertyTypeUseCase(sl()));

  // Use cases - unit types
  sl.registerLazySingleton<ut_uc1.GetUnitTypesByPropertyUseCase>(
      () => ut_uc1.GetUnitTypesByPropertyUseCase(sl()));
  sl.registerLazySingleton<ut_uc2.CreateUnitTypeUseCase>(
      () => ut_uc2.CreateUnitTypeUseCase(sl()));
  sl.registerLazySingleton<ut_uc3.UpdateUnitTypeUseCase>(
      () => ut_uc3.UpdateUnitTypeUseCase(sl()));
  sl.registerLazySingleton<ut_uc4.DeleteUnitTypeUseCase>(
      () => ut_uc4.DeleteUnitTypeUseCase(sl()));

  // Use cases - fields
  sl.registerLazySingleton<utf_uc1.GetFieldsByUnitTypeUseCase>(
      () => utf_uc1.GetFieldsByUnitTypeUseCase(sl()));
  sl.registerLazySingleton<utf_uc2.CreateFieldUseCase>(
      () => utf_uc2.CreateFieldUseCase(sl()));
  sl.registerLazySingleton<utf_uc3.UpdateFieldUseCase>(
      () => utf_uc3.UpdateFieldUseCase(sl()));
  sl.registerLazySingleton<utf_uc4.DeleteFieldUseCase>(
      () => utf_uc4.DeleteFieldUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<pt_domain.PropertyTypesRepository>(
      () => pt_data.PropertyTypesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton<ut_domain.UnitTypesRepository>(
      () => ut_data.UnitTypesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton<utf_domain.UnitTypeFieldsRepository>(
      () => utf_data.UnitTypeFieldsRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<pt_ds.PropertyTypesRemoteDataSource>(
      () => pt_ds.PropertyTypesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ut_ds.UnitTypesRemoteDataSource>(
      () => ut_ds.UnitTypesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<utf_ds.UnitTypeFieldsRemoteDataSource>(
      () => utf_ds.UnitTypeFieldsRemoteDataSourceImpl(apiClient: sl()));
}

void _initAdminProperties() {
  // Blocs
  sl.registerFactory(() => ap_bloc.PropertiesBloc(
        getAllProperties: sl<ap_uc_prop1.GetAllPropertiesUseCase>(),
        createProperty: sl<ap_uc_prop2.CreatePropertyUseCase>(),
        updateProperty: sl<ap_uc_prop3.UpdatePropertyUseCase>(),
        deleteProperty: sl<ap_uc_prop4.DeletePropertyUseCase>(),
        approveProperty: sl<ap_uc_prop5.ApprovePropertyUseCase>(),
        rejectProperty: sl<ap_uc_prop6.RejectPropertyUseCase>(),
        getPropertyDetails: sl<ap_uc_prop7.GetPropertyDetailsUseCase>(),
      ));
  sl.registerFactory(() => ap_am_bloc.AmenitiesBloc(
        getAmenities: sl<ap_uc_am1.GetAmenitiesUseCase>(),
        createAmenity: sl<ap_uc_am2.CreateAmenityUseCase>(),
        updateAmenity: sl<ap_uc_am3.UpdateAmenityUseCase>(),
        deleteAmenity: sl<ap_uc_am4.DeleteAmenityUseCase>(),
        assignAmenityToProperty: sl<ap_uc_am5.AssignAmenityToPropertyUseCase>(),
        unassignAmenityFromProperty:
            sl<ap_uc_am6.UnassignAmenityFromPropertyUseCase>(),
      ));
  sl.registerFactory(() => ap_po_bloc.PoliciesBloc(
        getPolicies: sl<ap_uc_po1.GetPoliciesUseCase>(),
        createPolicy: sl<ap_uc_po2.CreatePolicyUseCase>(),
        updatePolicy: sl<ap_uc_po3.UpdatePolicyUseCase>(),
        deletePolicy: sl<ap_uc_po4.DeletePolicyUseCase>(),
      ));
  sl.registerFactory(() => ap_pt_bloc.PropertyTypesBloc(
        getPropertyTypes: sl<ap_uc_pt1.GetPropertyTypesUseCase>(),
        createPropertyType: sl<ap_uc_pt2.CreatePropertyTypeUseCase>(),
        updatePropertyType: sl<ap_uc_pt3.UpdatePropertyTypeUseCase>(),
        deletePropertyType: sl<ap_uc_pt4.DeletePropertyTypeUseCase>(),
      ));

  // Property Images BLoC
  sl.registerFactory(
    () => PropertyImagesBloc(
      uploadPropertyImage: sl(),
      uploadMultipleImages: sl(),
      getPropertyImages: sl(),
      updatePropertyImage: sl(),
      deletePropertyImage: sl(),
      deleteMultipleImages: sl(),
      reorderImages: sl(),
      setPrimaryImage: sl(),
    ),
  );

  // Property Images Use Cases - إضافة UploadPropertyImageUseCase المفقود
  sl.registerLazySingleton(
      () => UploadPropertyImageUseCase(sl())); // هذا السطر كان مفقوداً
  sl.registerLazySingleton(() => GetPropertyImagesUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePropertyImageUseCase(sl()));
  sl.registerLazySingleton(() => DeletePropertyImageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMultipleImagesUseCase(sl()));
  sl.registerLazySingleton(() => ReorderImagesUseCase(sl()));
  sl.registerLazySingleton(() => SetPrimaryImageUseCase(sl()));
  sl.registerLazySingleton(() => UploadMultipleImagesUseCase(sl()));

  // Use cases - properties
  sl.registerLazySingleton<ap_uc_prop1.GetAllPropertiesUseCase>(
      () => ap_uc_prop1.GetAllPropertiesUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop2.CreatePropertyUseCase>(
      () => ap_uc_prop2.CreatePropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop3.UpdatePropertyUseCase>(
      () => ap_uc_prop3.UpdatePropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop_owner_update.OwnerUpdatePropertyUseCase>(
      () => ap_uc_prop_owner_update.OwnerUpdatePropertyUseCase(sl()));
  sl.registerLazySingleton<
          ap_uc_prop_public_details.GetPropertyDetailsPublicUseCase>(
      () => ap_uc_prop_public_details.GetPropertyDetailsPublicUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop4.DeletePropertyUseCase>(
      () => ap_uc_prop4.DeletePropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop5.ApprovePropertyUseCase>(
      () => ap_uc_prop5.ApprovePropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop6.RejectPropertyUseCase>(
      () => ap_uc_prop6.RejectPropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_prop7.GetPropertyDetailsUseCase>(
      () => ap_uc_prop7.GetPropertyDetailsUseCase(sl()));

  // Use cases - amenities
  sl.registerLazySingleton<ap_uc_am1.GetAmenitiesUseCase>(
      () => ap_uc_am1.GetAmenitiesUseCase(sl()));
  sl.registerLazySingleton<ap_uc_am2.CreateAmenityUseCase>(
      () => ap_uc_am2.CreateAmenityUseCase(sl()));
  sl.registerLazySingleton<ap_uc_am3.UpdateAmenityUseCase>(
      () => ap_uc_am3.UpdateAmenityUseCase(sl()));
  sl.registerLazySingleton<ap_uc_am4.DeleteAmenityUseCase>(
      () => ap_uc_am4.DeleteAmenityUseCase(sl()));
  sl.registerLazySingleton<ap_uc_am5.AssignAmenityToPropertyUseCase>(
      () => ap_uc_am5.AssignAmenityToPropertyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_am6.UnassignAmenityFromPropertyUseCase>(
      () => ap_uc_am6.UnassignAmenityFromPropertyUseCase(sl()));

  // Use cases - policies
  sl.registerLazySingleton<ap_uc_po1.GetPoliciesUseCase>(
      () => ap_uc_po1.GetPoliciesUseCase(sl()));
  sl.registerLazySingleton<ap_uc_po2.CreatePolicyUseCase>(
      () => ap_uc_po2.CreatePolicyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_po3.UpdatePolicyUseCase>(
      () => ap_uc_po3.UpdatePolicyUseCase(sl()));
  sl.registerLazySingleton<ap_uc_po4.DeletePolicyUseCase>(
      () => ap_uc_po4.DeletePolicyUseCase(sl()));

  // Use cases - property types
  sl.registerLazySingleton<ap_uc_pt1.GetPropertyTypesUseCase>(
      () => ap_uc_pt1.GetPropertyTypesUseCase(sl()));
  sl.registerLazySingleton<ap_uc_pt2.CreatePropertyTypeUseCase>(
      () => ap_uc_pt2.CreatePropertyTypeUseCase(sl()));
  sl.registerLazySingleton<ap_uc_pt3.UpdatePropertyTypeUseCase>(
      () => ap_uc_pt3.UpdatePropertyTypeUseCase(sl()));
  sl.registerLazySingleton<ap_uc_pt4.DeletePropertyTypeUseCase>(
      () => ap_uc_pt4.DeletePropertyTypeUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<ap_repo.PropertiesRepository>(
      () => ap_repo_impl.PropertiesRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  sl.registerLazySingleton<ap_am_repo.AmenitiesRepository>(
      () => ap_am_repo_impl.AmenitiesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton<ap_po_repo.PoliciesRepository>(
      () => ap_po_repo_impl.PoliciesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton<ap_pt_repo.PropertyTypesRepository>(
      () => ap_pt_repo_impl.PropertyTypesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));

  // Property Images Repository
  sl.registerLazySingleton<PropertyImagesRepository>(
    () => PropertyImagesRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Property Images Data Sources
  sl.registerLazySingleton<PropertyImagesRemoteDataSource>(
    () => PropertyImagesRemoteDataSourceImpl(apiClient: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ap_ds_prop_remote.PropertiesRemoteDataSource>(
      () => ap_ds_prop_remote.PropertiesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ap_ds_prop_local.PropertiesLocalDataSource>(() =>
      ap_ds_prop_local.PropertiesLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<ap_ds_am_remote.AmenitiesRemoteDataSource>(
      () => ap_ds_am_remote.AmenitiesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ap_ds_po_remote.PoliciesRemoteDataSource>(
      () => ap_ds_po_remote.PoliciesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ap_ds_pt_remote.PropertyTypesRemoteDataSource>(
      () => ap_ds_pt_remote.PropertyTypesRemoteDataSourceImpl(apiClient: sl()));
}

void _initAdminAvailabilityPricing() {
  // Blocs
  sl.registerFactory(() => AvailabilityBloc(
        getMonthlyAvailabilityUseCase:
            sl<aap_av_uc_get.GetMonthlyAvailabilityUseCase>(),
        updateAvailabilityUseCase:
            sl<aap_av_uc_update.UpdateAvailabilityUseCase>(),
        bulkUpdateAvailabilityUseCase:
            sl<aap_av_uc_bulk.BulkUpdateAvailabilityUseCase>(),
        checkAvailabilityUseCase:
            sl<aap_av_uc_check.CheckAvailabilityUseCase>(),
      ));
  sl.registerFactory(() => PricingBloc(
        getMonthlyPricingUseCase: sl<aap_pr_uc_get.GetMonthlyPricingUseCase>(),
        updatePricingUseCase: sl<aap_pr_uc_update.UpdatePricingUseCase>(),
        bulkUpdatePricingUseCase: sl<aap_pr_uc_bulk.BulkUpdatePricingUseCase>(),
        applySeasonalPricingUseCase:
            sl<aap_pr_uc_apply.ApplySeasonalPricingUseCase>(),
      ));

  // Use cases - Availability
  sl.registerLazySingleton<aap_av_uc_get.GetMonthlyAvailabilityUseCase>(
      () => aap_av_uc_get.GetMonthlyAvailabilityUseCase(sl()));
  sl.registerLazySingleton<aap_av_uc_update.UpdateAvailabilityUseCase>(
      () => aap_av_uc_update.UpdateAvailabilityUseCase(sl()));
  sl.registerLazySingleton<aap_av_uc_bulk.BulkUpdateAvailabilityUseCase>(
      () => aap_av_uc_bulk.BulkUpdateAvailabilityUseCase(sl()));
  sl.registerLazySingleton<aap_av_uc_check.CheckAvailabilityUseCase>(
      () => aap_av_uc_check.CheckAvailabilityUseCase(sl()));
  sl.registerLazySingleton<aap_av_uc_clone.CloneAvailabilityUseCase>(
      () => aap_av_uc_clone.CloneAvailabilityUseCase(sl()));
  sl.registerLazySingleton<aap_av_uc_delete.DeleteAvailabilityUseCase>(
      () => aap_av_uc_delete.DeleteAvailabilityUseCase(sl()));

  // Use cases - Pricing
  sl.registerLazySingleton<aap_pr_uc_get.GetMonthlyPricingUseCase>(
      () => aap_pr_uc_get.GetMonthlyPricingUseCase(sl()));
  sl.registerLazySingleton<aap_pr_uc_update.UpdatePricingUseCase>(
      () => aap_pr_uc_update.UpdatePricingUseCase(sl()));
  sl.registerLazySingleton<aap_pr_uc_bulk.BulkUpdatePricingUseCase>(
      () => aap_pr_uc_bulk.BulkUpdatePricingUseCase(sl()));
  sl.registerLazySingleton<aap_pr_uc_copy.CopyPricingUseCase>(
      () => aap_pr_uc_copy.CopyPricingUseCase(sl()));
  sl.registerLazySingleton<aap_pr_uc_delete.DeletePricingUseCase>(
      () => aap_pr_uc_delete.DeletePricingUseCase(sl()));
  sl.registerLazySingleton<aap_pr_uc_apply.ApplySeasonalPricingUseCase>(
      () => aap_pr_uc_apply.ApplySeasonalPricingUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<aap_av_repo.AvailabilityRepository>(
      () => aap_av_repo_impl.AvailabilityRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton<aap_pr_repo.PricingRepository>(
      () => aap_pr_repo_impl.PricingRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<aap_av_ds_remote.AvailabilityRemoteDataSource>(
      () => aap_av_ds_remote.AvailabilityRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<aap_av_ds_local.AvailabilityLocalDataSource>(() =>
      aap_av_ds_local.AvailabilityLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<aap_pr_ds_remote.PricingRemoteDataSource>(
      () => aap_pr_ds_remote.PricingRemoteDataSourceImpl(apiClient: sl()));
}

void _initAdminServices() {
  // Bloc
  sl.registerFactory(() => ServicesBloc(
        createServiceUseCase: sl<as_uc1.CreateServiceUseCase>(),
        updateServiceUseCase: sl<as_uc2.UpdateServiceUseCase>(),
        deleteServiceUseCase: sl<as_uc3.DeleteServiceUseCase>(),
        getServicesByPropertyUseCase: sl<as_uc4.GetServicesByPropertyUseCase>(),
        getServiceDetailsUseCase: sl<as_uc5.GetServiceDetailsUseCase>(),
        getServicesByTypeUseCase: sl<as_uc6.GetServicesByTypeUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<as_uc1.CreateServiceUseCase>(
      () => as_uc1.CreateServiceUseCase(sl()));
  sl.registerLazySingleton<as_uc2.UpdateServiceUseCase>(
      () => as_uc2.UpdateServiceUseCase(sl()));
  sl.registerLazySingleton<as_uc3.DeleteServiceUseCase>(
      () => as_uc3.DeleteServiceUseCase(sl()));
  sl.registerLazySingleton<as_uc4.GetServicesByPropertyUseCase>(
      () => as_uc4.GetServicesByPropertyUseCase(sl()));
  sl.registerLazySingleton<as_uc5.GetServiceDetailsUseCase>(
      () => as_uc5.GetServiceDetailsUseCase(sl()));
  sl.registerLazySingleton<as_uc6.GetServicesByTypeUseCase>(
      () => as_uc6.GetServicesByTypeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ServicesRepository>(
      () => ServicesRepositoryImpl(remoteDataSource: sl()));

  // Data source
  sl.registerLazySingleton<ServicesRemoteDataSource>(
      () => ServicesRemoteDataSourceImpl(apiClient: sl()));
}

void _initAdminReviews() {
  // Blocs
  sl.registerFactory(() => ar_list_bloc.ReviewsListBloc(
        getAllReviews: sl<ar_uc1.GetAllReviewsUseCase>(),
        approveReview: sl<ar_uc2.ApproveReviewUseCase>(),
        deleteReview: sl<ar_uc3.DeleteReviewUseCase>(),
      ));
  sl.registerFactory(() => ar_details_bloc.ReviewDetailsBloc(
        getReviewDetails: sl<ar_uc4.GetReviewDetailsUseCase>(),
        getReviewResponses: sl<ar_uc5.GetReviewResponsesUseCase>(),
        respondToReview: sl<ar_uc6.RespondToReviewUseCase>(),
        deleteReviewResponse: sl<ar_uc7.DeleteReviewResponseUseCase>(),
      ));
  sl.registerFactory(() => ar_resp_bloc.ReviewResponseBloc(
        respondToReview: sl<ar_uc6.RespondToReviewUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<ar_uc1.GetAllReviewsUseCase>(
      () => ar_uc1.GetAllReviewsUseCase(sl()));
  sl.registerLazySingleton<ar_uc2.ApproveReviewUseCase>(
      () => ar_uc2.ApproveReviewUseCase(sl()));
  sl.registerLazySingleton<ar_uc3.DeleteReviewUseCase>(
      () => ar_uc3.DeleteReviewUseCase(sl()));
  sl.registerLazySingleton<ar_uc4.GetReviewDetailsUseCase>(
      () => ar_uc4.GetReviewDetailsUseCase(sl()));
  sl.registerLazySingleton<ar_uc5.GetReviewResponsesUseCase>(
      () => ar_uc5.GetReviewResponsesUseCase(sl()));
  sl.registerLazySingleton<ar_uc6.RespondToReviewUseCase>(
      () => ar_uc6.RespondToReviewUseCase(sl()));
  sl.registerLazySingleton<ar_uc7.DeleteReviewResponseUseCase>(
      () => ar_uc7.DeleteReviewResponseUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ar_repo.ReviewsRepository>(
      () => ar_repo_impl.ReviewsRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<ar_ds_remote.ReviewsRemoteDataSource>(
    () => ar_ds_remote.ReviewsRemoteDataSourceImpl(
      apiClient: sl(),
      localStorage: sl(),
    ),
  );
  sl.registerLazySingleton<ar_ds_local.ReviewsLocalDataSource>(
      () => ar_ds_local.ReviewsLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initAdminAuditLogs() {
  // Bloc
  sl.registerFactory(() => AuditLogsBloc(
        getAuditLogsUseCase: sl<al_uc_get.GetAuditLogsUseCase>(),
        exportAuditLogsUseCase: sl<al_uc_export.ExportAuditLogsUseCase>(),
        repository: sl<al_repo.AuditLogsRepository>(),
      ));

  // Use cases
  sl.registerLazySingleton<al_uc_get.GetAuditLogsUseCase>(
    () => al_uc_get.GetAuditLogsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<al_uc_export.ExportAuditLogsUseCase>(
    () => al_uc_export.ExportAuditLogsUseCase(repository: sl()),
  );
  // Optional extra use cases for other activity views
  sl.registerLazySingleton<al_uc_get_cust.GetCustomerActivityLogsUseCase>(
    () => al_uc_get_cust.GetCustomerActivityLogsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<al_uc_get_prop.GetPropertyActivityLogsUseCase>(
    () => al_uc_get_prop.GetPropertyActivityLogsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<al_uc_get_admin.GetAdminActivityLogsUseCase>(
    () => al_uc_get_admin.GetAdminActivityLogsUseCase(repository: sl()),
  );

  // Repository
  sl.registerLazySingleton<al_repo.AuditLogsRepository>(
      () => al_repo_impl.AuditLogsRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<al_ds_remote.AuditLogsRemoteDataSource>(
    () => al_ds_remote.AuditLogsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<al_ds_local.AuditLogsLocalDataSource>(
    () => al_ds_local.AuditLogsLocalDataSourceImpl(),
  );
}

void _initAdminAmenities() {
  // Bloc
  sl.registerFactory(() => aa_bloc.AmenitiesBloc(
        createAmenityUseCase: sl<aa_uc1.CreateAmenityUseCase>(),
        updateAmenityUseCase: sl<aa_uc2.UpdateAmenityUseCase>(),
        deleteAmenityUseCase: sl<aa_uc3.DeleteAmenityUseCase>(),
        getAllAmenitiesUseCase: sl<aa_uc4.GetAllAmenitiesUseCase>(),
        assignAmenityToPropertyUseCase:
            sl<aa_uc5.AssignAmenityToPropertyUseCase>(),
        repository: sl(),
      ));

  // Use cases
  sl.registerLazySingleton<aa_uc1.CreateAmenityUseCase>(
      () => aa_uc1.CreateAmenityUseCase(sl()));
  sl.registerLazySingleton<aa_uc2.UpdateAmenityUseCase>(
      () => aa_uc2.UpdateAmenityUseCase(sl()));
  sl.registerLazySingleton<aa_uc3.DeleteAmenityUseCase>(
      () => aa_uc3.DeleteAmenityUseCase(sl()));
  sl.registerLazySingleton<aa_uc4.GetAllAmenitiesUseCase>(
      () => aa_uc4.GetAllAmenitiesUseCase(sl()));
  sl.registerLazySingleton<aa_uc5.AssignAmenityToPropertyUseCase>(
      () => aa_uc5.AssignAmenityToPropertyUseCase(sl()));

  // Repository
  sl.registerLazySingleton<aa_repo.AmenitiesRepository>(
      () => aa_repo_impl.AmenitiesRepositoryImpl(remoteDataSource: sl()));

  // Data source
  sl.registerLazySingleton<aa_ds_remote.AmenitiesRemoteDataSource>(
      () => aa_ds_remote.AmenitiesRemoteDataSourceImpl(apiClient: sl()));
}

void _initAdminPolicies() {
  // Bloc
  sl.registerFactory(() => apo_bloc.PoliciesBloc(
        createPolicyUseCase: sl<apo_uc1.CreatePolicyUseCase>(),
        updatePolicyUseCase: sl<apo_uc2.UpdatePolicyUseCase>(),
        deletePolicyUseCase: sl<apo_uc3.DeletePolicyUseCase>(),
        getAllPoliciesUseCase: sl<apo_uc4.GetAllPoliciesUseCase>(),
        getPolicyByIdUseCase: sl<apo_uc5.GetPolicyByIdUseCase>(),
        getPoliciesByPropertyUseCase:
            sl<apo_uc6.GetPoliciesByPropertyUseCase>(),
        getPoliciesByTypeUseCase: sl<apo_uc7.GetPoliciesByTypeUseCase>(),
        togglePolicyStatusUseCase: sl<apo_uc8.TogglePolicyStatusUseCase>(),
        repository: sl(),
      ));

  // Use cases
  sl.registerLazySingleton<apo_uc1.CreatePolicyUseCase>(
      () => apo_uc1.CreatePolicyUseCase(sl()));
  sl.registerLazySingleton<apo_uc2.UpdatePolicyUseCase>(
      () => apo_uc2.UpdatePolicyUseCase(sl()));
  sl.registerLazySingleton<apo_uc3.DeletePolicyUseCase>(
      () => apo_uc3.DeletePolicyUseCase(sl()));
  sl.registerLazySingleton<apo_uc4.GetAllPoliciesUseCase>(
      () => apo_uc4.GetAllPoliciesUseCase(sl()));
  sl.registerLazySingleton<apo_uc5.GetPolicyByIdUseCase>(
      () => apo_uc5.GetPolicyByIdUseCase(sl()));
  sl.registerLazySingleton<apo_uc6.GetPoliciesByPropertyUseCase>(
      () => apo_uc6.GetPoliciesByPropertyUseCase(sl()));
  sl.registerLazySingleton<apo_uc7.GetPoliciesByTypeUseCase>(
      () => apo_uc7.GetPoliciesByTypeUseCase(sl()));
  sl.registerLazySingleton<apo_uc8.TogglePolicyStatusUseCase>(
      () => apo_uc8.TogglePolicyStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<apo_repo.PoliciesRepository>(
      () => apo_repo_impl.PoliciesRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<apo_ds_remote.PoliciesRemoteDataSource>(
      () => apo_ds_remote.PoliciesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<apo_ds_local.PoliciesLocalDataSource>(
      () => apo_ds_local.PoliciesLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initAdminCurrencies() {
  // Bloc
  sl.registerFactory(() => ac_bloc.CurrenciesBloc(
        getCurrencies: sl<ac_uc1.GetCurrenciesUseCase>(),
        saveCurrencies: sl<ac_uc2.SaveCurrenciesUseCase>(),
        deleteCurrency: sl<ac_uc3.DeleteCurrencyUseCase>(),
        setDefaultCurrency: sl<ac_uc4.SetDefaultCurrencyUseCase>(),
        repository: sl<ac_repo.CurrenciesRepository>(),
      ));

  // Use cases
  sl.registerLazySingleton<ac_uc1.GetCurrenciesUseCase>(
      () => ac_uc1.GetCurrenciesUseCase(sl()));
  sl.registerLazySingleton<ac_uc2.SaveCurrenciesUseCase>(
      () => ac_uc2.SaveCurrenciesUseCase(sl()));
  sl.registerLazySingleton<ac_uc3.DeleteCurrencyUseCase>(
      () => ac_uc3.DeleteCurrencyUseCase(sl()));
  sl.registerLazySingleton<ac_uc4.SetDefaultCurrencyUseCase>(
      () => ac_uc4.SetDefaultCurrencyUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ac_repo.CurrenciesRepository>(
      () => ac_repo_impl.CurrenciesRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<ac_ds_remote.CurrenciesRemoteDataSource>(
      () => ac_ds_remote.CurrenciesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ac_ds_local.CurrenciesLocalDataSource>(
      () => ac_ds_local.CurrenciesLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initAdminCities() {
  // Bloc
  sl.registerFactory(() => ci_bloc.CitiesBloc(
        getCities: sl<ci_uc1.GetCitiesUseCase>(),
        saveCities: sl<ci_uc2.SaveCitiesUseCase>(),
        createCity: sl<ci_uc3.CreateCityUseCase>(),
        updateCity: sl<ci_uc4.UpdateCityUseCase>(),
        deleteCity: sl<ci_uc5.DeleteCityUseCase>(),
        searchCities: sl<ci_uc6.SearchCitiesUseCase>(),
        getCitiesStatistics: sl<ci_uc7.GetCitiesStatisticsUseCase>(),
        uploadCityImage: sl<ci_uc8.UploadCityImageUseCase>(),
        deleteCityImage: sl<ci_uc9.DeleteCityImageUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<ci_uc1.GetCitiesUseCase>(
      () => ci_uc1.GetCitiesUseCase(sl()));
  sl.registerLazySingleton<ci_uc2.SaveCitiesUseCase>(
      () => ci_uc2.SaveCitiesUseCase(sl()));
  sl.registerLazySingleton<ci_uc3.CreateCityUseCase>(
      () => ci_uc3.CreateCityUseCase(sl()));
  sl.registerLazySingleton<ci_uc4.UpdateCityUseCase>(
      () => ci_uc4.UpdateCityUseCase(sl()));
  sl.registerLazySingleton<ci_uc5.DeleteCityUseCase>(
      () => ci_uc5.DeleteCityUseCase(sl()));
  sl.registerLazySingleton<ci_uc6.SearchCitiesUseCase>(
      () => ci_uc6.SearchCitiesUseCase(sl()));
  sl.registerLazySingleton<ci_uc7.GetCitiesStatisticsUseCase>(
      () => ci_uc7.GetCitiesStatisticsUseCase(sl()));
  sl.registerLazySingleton<ci_uc8.UploadCityImageUseCase>(
      () => ci_uc8.UploadCityImageUseCase(sl()));
  sl.registerLazySingleton<ci_uc9.DeleteCityImageUseCase>(
      () => ci_uc9.DeleteCityImageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ci_repo.CitiesRepository>(
      () => ci_repo_impl.CitiesRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<ci_ds_remote.CitiesRemoteDataSource>(
      () => ci_ds_remote.CitiesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ci_ds_local.CitiesLocalDataSource>(
      () => ci_ds_local.CitiesLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initHelpers() {
  // Use cases
  sl.registerLazySingleton<helpers_uc_users.SearchUsersUseCase>(
      () => helpers_uc_users.SearchUsersUseCase(sl()));
  sl.registerLazySingleton<helpers_uc_props.SearchPropertiesUseCase>(
      () => helpers_uc_props.SearchPropertiesUseCase(sl()));
  sl.registerLazySingleton<helpers_uc_units.SearchUnitsUseCase>(
      () => helpers_uc_units.SearchUnitsUseCase(sl()));
  sl.registerLazySingleton<helpers_uc_cities.SearchCitiesUseCase>(
      () => helpers_uc_cities.SearchCitiesUseCase(sl()));
  sl.registerLazySingleton<helpers_uc_bookings.SearchBookingsUseCase>(
      () => helpers_uc_bookings.SearchBookingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<helpers_repo.HelpersRepository>(
      () => helpers_repo_impl.HelpersRepositoryImpl(
            remoteDataSource: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<helpers_ds.HelpersRemoteDataSource>(
      () => helpers_ds.HelpersRemoteDataSourceImpl(sl()));
}

void _initAdminUsers() {
  // Blocs
  sl.registerFactory(() => UsersListBloc(
        getAllUsersUseCase: sl<au_uc1.GetAllUsersUseCase>(),
        activateUserUseCase: sl<au_uc5.ActivateUserUseCase>(),
        deactivateUserUseCase: sl<au_uc6.DeactivateUserUseCase>(),
        createUserUseCase: sl<au_uc3.CreateUserUseCase>(),
        updateUserUseCase: sl<au_uc4.UpdateUserUseCase>(),
        assignRoleUseCase: sl<au_uc7.AssignRoleUseCase>(),
      ));
  sl.registerFactory(() => UserDetailsBloc(
        getUserDetailsUseCase: sl<au_uc2.GetUserDetailsUseCase>(),
        getUserLifetimeStatsUseCase: sl<au_uc8.GetUserLifetimeStatsUseCase>(),
        updateUserUseCase: sl<au_uc4.UpdateUserUseCase>(),
        activateUserUseCase: sl<au_uc5.ActivateUserUseCase>(),
        deactivateUserUseCase: sl<au_uc6.DeactivateUserUseCase>(),
        assignRoleUseCase: sl<au_uc7.AssignRoleUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<au_uc1.GetAllUsersUseCase>(
      () => au_uc1.GetAllUsersUseCase(sl()));
  sl.registerLazySingleton<au_uc2.GetUserDetailsUseCase>(
      () => au_uc2.GetUserDetailsUseCase(sl()));
  sl.registerLazySingleton<au_uc3.CreateUserUseCase>(
      () => au_uc3.CreateUserUseCase(sl()));
  sl.registerLazySingleton<au_uc4.UpdateUserUseCase>(
      () => au_uc4.UpdateUserUseCase(sl()));
  sl.registerLazySingleton<au_uc5.ActivateUserUseCase>(
      () => au_uc5.ActivateUserUseCase(sl()));
  sl.registerLazySingleton<au_uc6.DeactivateUserUseCase>(
      () => au_uc6.DeactivateUserUseCase(sl()));
  sl.registerLazySingleton<au_uc7.AssignRoleUseCase>(
      () => au_uc7.AssignRoleUseCase(sl()));
  sl.registerLazySingleton<au_uc8.GetUserLifetimeStatsUseCase>(
      () => au_uc8.GetUserLifetimeStatsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<au_repo.UsersRepository>(
      () => au_repo_impl.UsersRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<au_ds_remote.UsersRemoteDataSource>(
      () => au_ds_remote.UsersRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<au_ds_local.UsersLocalDataSource>(
      () => au_ds_local.UsersLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initAdminBookings() {
  // Blocs
  sl.registerFactory(() => ab_list_bloc.BookingsListBloc(
        cancelBookingUseCase: sl<ab_uc_cancel.CancelBookingUseCase>(),
        updateBookingUseCase: sl<ab_uc_update.UpdateBookingUseCase>(),
        confirmBookingUseCase: sl<ab_uc_confirm.ConfirmBookingUseCase>(),
        getBookingsByDateRangeUseCase:
            sl<ab_uc_get_by_range.GetBookingsByDateRangeUseCase>(),
        checkInUseCase: sl<ab_uc_checkin.CheckInUseCase>(),
        checkOutUseCase: sl<ab_uc_checkout.CheckOutUseCase>(),
      ));
  sl.registerFactory(() => ab_details_bloc.BookingDetailsBloc(
        getBookingByIdUseCase: sl<ab_uc_get_by_id.GetBookingByIdUseCase>(),
        cancelBookingUseCase: sl<ab_uc_cancel.CancelBookingUseCase>(),
        updateBookingUseCase: sl<ab_uc_update.UpdateBookingUseCase>(),
        confirmBookingUseCase: sl<ab_uc_confirm.ConfirmBookingUseCase>(),
        checkInUseCase: sl<ab_uc_checkin.CheckInUseCase>(),
        checkOutUseCase: sl<ab_uc_checkout.CheckOutUseCase>(),
        addServiceToBookingUseCase:
            sl<ab_uc_add_service.AddServiceToBookingUseCase>(),
        removeServiceFromBookingUseCase:
            sl<ab_uc_remove_service.RemoveServiceFromBookingUseCase>(),
        getBookingServicesUseCase:
            sl<ab_uc_get_services.GetBookingServicesUseCase>(),
        repository: sl<ab_repo.BookingsRepository>(),
        reviewsRepository: sl<ar_repo.ReviewsRepository>(),
      ));
  sl.registerFactory(() => ab_register_payment_bloc.RegisterPaymentBloc(
        registerBookingPaymentUseCase:
            sl<ab_uc_register_payment.RegisterBookingPaymentUseCase>(),
      ));

  // Use cases - bookings
  sl.registerLazySingleton<ab_uc_cancel.CancelBookingUseCase>(
      () => ab_uc_cancel.CancelBookingUseCase(sl()));
  sl.registerLazySingleton<ab_uc_update.UpdateBookingUseCase>(
      () => ab_uc_update.UpdateBookingUseCase(sl()));
  sl.registerLazySingleton<ab_uc_confirm.ConfirmBookingUseCase>(
      () => ab_uc_confirm.ConfirmBookingUseCase(sl()));
  sl.registerLazySingleton<ab_uc_checkin.CheckInUseCase>(
      () => ab_uc_checkin.CheckInUseCase(sl()));
  sl.registerLazySingleton<ab_uc_checkout.CheckOutUseCase>(
      () => ab_uc_checkout.CheckOutUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_id.GetBookingByIdUseCase>(
      () => ab_uc_get_by_id.GetBookingByIdUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_range.GetBookingsByDateRangeUseCase>(
      () => ab_uc_get_by_range.GetBookingsByDateRangeUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_property.GetBookingsByPropertyUseCase>(
      () => ab_uc_get_by_property.GetBookingsByPropertyUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_status.GetBookingsByStatusUseCase>(
      () => ab_uc_get_by_status.GetBookingsByStatusUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_user.GetBookingsByUserUseCase>(
      () => ab_uc_get_by_user.GetBookingsByUserUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_by_unit.GetBookingsByUnitUseCase>(
      () => ab_uc_get_by_unit.GetBookingsByUnitUseCase(sl()));
  sl.registerLazySingleton<ab_uc_complete.CompleteBookingUseCase>(
      () => ab_uc_complete.CompleteBookingUseCase(sl()));
  sl.registerLazySingleton<ab_uc_upcoming.GetUpcomingBookingsUseCase>(
      () => ab_uc_upcoming.GetUpcomingBookingsUseCase(sl()));

  // Use cases - services
  sl.registerLazySingleton<ab_uc_add_service.AddServiceToBookingUseCase>(
      () => ab_uc_add_service.AddServiceToBookingUseCase(sl()));
  sl.registerLazySingleton<
          ab_uc_remove_service.RemoveServiceFromBookingUseCase>(
      () => ab_uc_remove_service.RemoveServiceFromBookingUseCase(sl()));
  sl.registerLazySingleton<ab_uc_get_services.GetBookingServicesUseCase>(
      () => ab_uc_get_services.GetBookingServicesUseCase(sl()));
  sl.registerLazySingleton<
          ab_uc_register_payment.RegisterBookingPaymentUseCase>(
      () => ab_uc_register_payment.RegisterBookingPaymentUseCase(sl()));

  // Use cases - reports
  sl.registerLazySingleton<ab_uc_report.GetBookingReportUseCase>(
      () => ab_uc_report.GetBookingReportUseCase(sl()));
  sl.registerLazySingleton<ab_uc_trends.GetBookingTrendsUseCase>(
      () => ab_uc_trends.GetBookingTrendsUseCase(sl()));
  sl.registerLazySingleton<ab_uc_window.GetBookingWindowAnalysisUseCase>(
      () => ab_uc_window.GetBookingWindowAnalysisUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ab_repo.BookingsRepository>(
    () => ab_repo_impl.BookingsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Calendar & Analytics Blocs
  sl.registerFactory(() => ab_cal_bloc.BookingCalendarBloc(
        getBookingsByDateRangeUseCase: sl(),
        getBookingsByUnitUseCase: sl(),
        getBookingsByPropertyUseCase: sl(),
      ));
  sl.registerFactory(() => ab_an_bloc.BookingAnalyticsBloc(
        getBookingReportUseCase: sl(),
        getBookingTrendsUseCase: sl(),
        getBookingWindowAnalysisUseCase: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<ab_ds_remote.BookingsRemoteDataSource>(
    () => ab_ds_remote.BookingsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ab_ds_local.BookingsLocalDataSource>(
    () => ab_ds_local.BookingsLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

void _initAdminPayments() {
  // Blocs
  sl.registerFactory(() => pay_list_bloc.PaymentsListBloc(
        refundPaymentUseCase: sl(),
        voidPaymentUseCase: sl(),
        updatePaymentStatusUseCase: sl(),
        getAllPaymentsUseCase: sl(),
      ));
  sl.registerFactory(() => pay_details_bloc.PaymentDetailsBloc(
        getPaymentByIdUseCase: sl(),
        refundPaymentUseCase: sl(),
        voidPaymentUseCase: sl(),
        updatePaymentStatusUseCase: sl(),
        repository: sl(),
      ));
  sl.registerFactory(() => pay_refund_bloc.PaymentRefundBloc(
        refundPaymentUseCase: sl(),
        getPaymentByIdUseCase: sl(),
        repository: sl(),
      ));
  sl.registerFactory(() => pay_an_bloc.PaymentAnalyticsBloc(
        getPaymentAnalyticsUseCase: sl(),
        getRevenueReportUseCase: sl(),
        getPaymentTrendsUseCase: sl(),
        getRefundStatisticsUseCase: sl(),
      ));

  // Use cases - payments commands
  sl.registerLazySingleton<pay_uc_refund.RefundPaymentUseCase>(
      () => pay_uc_refund.RefundPaymentUseCase(sl()));
  sl.registerLazySingleton<pay_uc_void.VoidPaymentUseCase>(
      () => pay_uc_void.VoidPaymentUseCase(sl()));
  sl.registerLazySingleton<pay_uc_update_status.UpdatePaymentStatusUseCase>(
      () => pay_uc_update_status.UpdatePaymentStatusUseCase(sl()));
  sl.registerLazySingleton<pay_uc_process.ProcessPaymentUseCase>(
      () => pay_uc_process.ProcessPaymentUseCase(sl()));
  sl.registerLazySingleton<pay_uc_get_by_id.GetPaymentByIdUseCase>(
      () => pay_uc_get_by_id.GetPaymentByIdUseCase(sl()));

  // Use cases - payments queries
  sl.registerLazySingleton<pay_uc_get_all.GetAllPaymentsUseCase>(
      () => pay_uc_get_all.GetAllPaymentsUseCase(sl()));
  sl.registerLazySingleton<pay_uc_by_booking.GetPaymentsByBookingUseCase>(
      () => pay_uc_by_booking.GetPaymentsByBookingUseCase(sl()));
  sl.registerLazySingleton<pay_uc_by_status.GetPaymentsByStatusUseCase>(
      () => pay_uc_by_status.GetPaymentsByStatusUseCase(sl()));
  sl.registerLazySingleton<pay_uc_by_user.GetPaymentsByUserUseCase>(
      () => pay_uc_by_user.GetPaymentsByUserUseCase(sl()));
  sl.registerLazySingleton<pay_uc_by_property.GetPaymentsByPropertyUseCase>(
      () => pay_uc_by_property.GetPaymentsByPropertyUseCase(sl()));
  sl.registerLazySingleton<pay_uc_by_method.GetPaymentsByMethodUseCase>(
      () => pay_uc_by_method.GetPaymentsByMethodUseCase(sl()));

  // Use cases - analytics
  sl.registerLazySingleton<pay_uc_analytics.GetPaymentAnalyticsUseCase>(
      () => pay_uc_analytics.GetPaymentAnalyticsUseCase(sl()));
  sl.registerLazySingleton<pay_uc_revenue.GetRevenueReportUseCase>(
      () => pay_uc_revenue.GetRevenueReportUseCase(sl()));
  sl.registerLazySingleton<pay_uc_trends.GetPaymentTrendsUseCase>(
      () => pay_uc_trends.GetPaymentTrendsUseCase(sl()));
  sl.registerLazySingleton<pay_uc_refund_stats.GetRefundStatisticsUseCase>(
      () => pay_uc_refund_stats.GetRefundStatisticsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<pay_repo.PaymentsRepository>(
      () => pay_repo_impl.PaymentsRepositoryImpl(
            remoteDataSource: sl(),
            localDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<pay_ds_remote.PaymentsRemoteDataSource>(
      () => pay_ds_remote.PaymentsRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<pay_ds_local.PaymentsLocalDataSource>(
      () => pay_ds_local.PaymentsLocalDataSourceImpl(sharedPreferences: sl()));
}

void _initTheme() {
  // Bloc
  sl.registerFactory(
    () => ThemeBloc(
      prefs: sl(),
    ),
  );
}

void _initOnboarding() {
  sl.registerFactory(() => onboarding_bloc.OnboardingBloc(
        localStorage: sl(),
        getCitiesUseCase: sl<ref_uc_cities.GetCitiesUseCase>(),
        getCurrenciesUseCase: sl<ref_uc_currencies.GetCurrenciesUseCase>(),
      ));
}

void _initReference() {
  // Bloc
  sl.registerFactory(() => ref_bloc.ReferenceBloc(
        getCitiesUseCase: sl<ref_uc_cities.GetCitiesUseCase>(),
        getCurrenciesUseCase: sl<ref_uc_currencies.GetCurrenciesUseCase>(),
        localStorage: sl(),
      ));

  // Use cases
  sl.registerLazySingleton<ref_uc_cities.GetCitiesUseCase>(
      () => ref_uc_cities.GetCitiesUseCase(sl()));
  sl.registerLazySingleton<ref_uc_currencies.GetCurrenciesUseCase>(
      () => ref_uc_currencies.GetCurrenciesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ref_repo.ReferenceRepository>(
      () => ref_repo_impl.ReferenceRepositoryImpl(
            remote: sl(),
            local: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<ref_ds_remote.ReferenceRemoteDataSource>(
      () => ref_ds_remote.ReferenceRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ref_ds_local.ReferenceLocalDataSource>(
      () => ref_ds_local.ReferenceLocalDataSourceImpl(localStorage: sl()));
}

void _initAdminSections() {
  // Use cases
  sl.registerLazySingleton(() => GetAllSectionsUseCase(sl()));
  sl.registerLazySingleton(() => GetSectionByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateSectionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSectionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSectionUseCase(sl()));
  sl.registerLazySingleton(() => ToggleSectionStatusUseCase(sl()));

  sl.registerLazySingleton(() => GetSectionItemsUseCase(sl()));
  sl.registerLazySingleton(() => AddItemsToSectionUseCase(sl()));
  sl.registerLazySingleton(() => RemoveItemsFromSectionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateItemOrderUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SectionsRepository>(() => SectionsRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<SectionsRemoteDataSource>(
      () => SectionsRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<SectionsLocalDataSource>(
      () => SectionsLocalDataSourceImpl(sharedPreferences: sl()));

  // Services facade
  sl.registerLazySingleton(() => SectionService(
        getAllSections: sl(),
        createSection: sl(),
        updateSection: sl(),
        deleteSection: sl(),
        toggleStatus: sl(),
        getById: sl(),
      ));
  sl.registerLazySingleton(() => SectionContentService(
        getItems: sl(),
        addItems: sl(),
        removeItems: sl(),
        reorderItems: sl(),
      ));

  // Section images remote datasources (DI only; repositories can be added if needed by BLoC)
  sl.registerLazySingleton<SectionImagesRemoteDataSource>(
      () => SectionImagesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<PropertyInSectionImagesRemoteDataSource>(
      () => PropertyInSectionImagesRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<UnitInSectionImagesRemoteDataSource>(
      () => UnitInSectionImagesRemoteDataSourceImpl(apiClient: sl()));

  // Section Images Repository + UseCases + Bloc
  sl.registerLazySingleton<SectionImagesRepository>(
      () => SectionImagesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton(() => UploadSectionImageUseCase(sl()));
  sl.registerLazySingleton(() => UploadMultipleSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => GetSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSectionImageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSectionImageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMultipleSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => ReorderSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => SetPrimarySectionImageUseCase(sl()));
  sl.registerFactory(() => SectionImagesBloc(
        uploadSectionImage: sl(),
        uploadMultipleImages: sl(),
        getSectionImages: sl(),
        updateSectionImage: sl(),
        deleteSectionImage: sl(),
        deleteMultipleImages: sl(),
        reorderImages: sl(),
        setPrimaryImage: sl(),
      ));

  // PropertyInSection Images Repository + UseCases + Bloc
  sl.registerLazySingleton<PropertyInSectionImagesRepository>(
      () => PropertyInSectionImagesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton(
      () => pis_uc.UploadPropertyInSectionImageUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.UploadMultiplePropertyInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.GetPropertyInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.UpdatePropertyInSectionImageUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.DeletePropertyInSectionImageUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.DeleteMultiplePropertyInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.ReorderPropertyInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => pis_uc.SetPrimaryPropertyInSectionImageUseCase(sl()));
  sl.registerFactory(() => PropertyInSectionImagesBloc(
        uploadImage: sl(),
        uploadMultipleImages: sl(),
        getImages: sl(),
        updateImage: sl(),
        deleteImage: sl(),
        deleteMultipleImages: sl(),
        reorderImages: sl(),
        setPrimaryImage: sl(),
      ));

  // UnitInSection Images Repository + UseCases + Bloc
  sl.registerLazySingleton<UnitInSectionImagesRepository>(
      () => UnitInSectionImagesRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));
  sl.registerLazySingleton(() => uis_uc.UploadUnitInSectionImageUseCase(sl()));
  sl.registerLazySingleton(
      () => uis_uc.UploadMultipleUnitInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => uis_uc.GetUnitInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(() => uis_uc.UpdateUnitInSectionImageUseCase(sl()));
  sl.registerLazySingleton(() => uis_uc.DeleteUnitInSectionImageUseCase(sl()));
  sl.registerLazySingleton(
      () => uis_uc.DeleteMultipleUnitInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => uis_uc.ReorderUnitInSectionImagesUseCase(sl()));
  sl.registerLazySingleton(
      () => uis_uc.SetPrimaryUnitInSectionImageUseCase(sl()));
  sl.registerFactory(() => UnitInSectionImagesBloc(
        uploadImage: sl(),
        uploadMultipleImages: sl(),
        getImages: sl(),
        updateImage: sl(),
        deleteImage: sl(),
        deleteMultipleImages: sl(),
        reorderImages: sl(),
        setPrimaryImage: sl(),
      ));

  // Admin Sections BLoCs (list, form, items management)
  sl.registerFactory(() => SectionsListBloc(
        getAllSections: sl(),
        deleteSection: sl(),
        toggleStatus: sl(),
      ));
  sl.registerFactory(() => SectionFormBloc(
        createSection: sl(),
        updateSection: sl(),
        getSectionById: sl(),
      ));
  sl.registerFactory(() => SectionItemsBloc(
        getItems: sl(),
        addItems: sl(),
        removeItems: sl(),
        reorderItems: sl(),
      ));
}

void _initCore() {
  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // API Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Services
  sl.registerLazySingleton(() => LocalStorageService(sl()));
  sl.registerLazySingleton(() => BiometricAuthService());
  sl.registerLazySingleton(() => LocationService());
  sl.registerLazySingleton(() => ScreenSearchService(sl()));
  sl.registerLazySingleton(() => NotificationService(
        apiClient: sl(),
        localStorage: sl(),
        authLocalDataSource: sl(),
      ));
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => DeepLinkService());
  sl.registerLazySingleton(() => MediaPipeline());

  // Data Management Services
  sl.registerLazySingleton(() => LocalDataService(sl()));
  sl.registerLazySingleton(() => ConnectivityService());

  // Reference module wiring is handled in _initReference()

  // Data sync service
  sl.registerLazySingleton(() => DataSyncService());

  // Removed generic WebSocketService registration; using ChatWebSocketService for chat feature
}

Future<void> _initExternal() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Dio
  sl.registerLazySingleton(() => Dio());

  // Internet Connection Checker (force IPv4 addresses to avoid IPv6 DNS issues)
  sl.registerLazySingleton(
      () => InternetConnectionChecker.createInstance(addresses: [
            AddressCheckOptions(
                address: io.InternetAddress.tryParse('1.1.1.1')!, port: 53),
            AddressCheckOptions(
                address: io.InternetAddress.tryParse('8.8.8.8')!, port: 53),
          ]));
}

void _initAdminNotifications() {
  // Bloc
  sl.registerFactory(() => an_bloc.AdminNotificationsBloc(
        createUseCase: sl<an_uc_create.CreateAdminNotificationUseCase>(),
        broadcastUseCase:
            sl<an_uc_broadcast.BroadcastAdminNotificationUseCase>(),
        deleteUseCase: sl<an_uc_delete.DeleteAdminNotificationUseCase>(),
        resendUseCase: sl<an_uc_resend.ResendAdminNotificationUseCase>(),
        getSystemUseCase:
            sl<an_uc_get_system.GetSystemAdminNotificationsUseCase>(),
        getUserUseCase: sl<an_uc_get_user.GetUserAdminNotificationsUseCase>(),
        getStatsUseCase: sl<an_uc_stats.GetAdminNotificationsStatsUseCase>(),
      ));

  // Use cases
  sl.registerLazySingleton<an_uc_create.CreateAdminNotificationUseCase>(
      () => an_uc_create.CreateAdminNotificationUseCase(sl()));
  sl.registerLazySingleton<an_uc_broadcast.BroadcastAdminNotificationUseCase>(
      () => an_uc_broadcast.BroadcastAdminNotificationUseCase(sl()));
  sl.registerLazySingleton<an_uc_delete.DeleteAdminNotificationUseCase>(
      () => an_uc_delete.DeleteAdminNotificationUseCase(sl()));
  sl.registerLazySingleton<an_uc_resend.ResendAdminNotificationUseCase>(
      () => an_uc_resend.ResendAdminNotificationUseCase(sl()));
  sl.registerLazySingleton<an_uc_get_system.GetSystemAdminNotificationsUseCase>(
      () => an_uc_get_system.GetSystemAdminNotificationsUseCase(sl()));
  sl.registerLazySingleton<an_uc_get_user.GetUserAdminNotificationsUseCase>(
      () => an_uc_get_user.GetUserAdminNotificationsUseCase(sl()));
  sl.registerLazySingleton<an_uc_stats.GetAdminNotificationsStatsUseCase>(
      () => an_uc_stats.GetAdminNotificationsStatsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<an_repo.AdminNotificationsRepository>(() =>
      an_repo_impl.AdminNotificationsRepositoryImpl(
          remote: sl(), networkInfo: sl()));

  // Data source
  sl.registerLazySingleton<an_ds_remote.AdminNotificationsRemoteDataSource>(
      () => an_ds_remote.AdminNotificationsRemoteDataSource(apiClient: sl()));
}

void _initAdminFinancial() {
  // Blocs
  sl.registerFactory(() => AccountsBloc(repository: sl()));
  sl.registerFactory(() => TransactionsBloc(repository: sl()));
  sl.registerFactory(() => FinancialOverviewBloc(
        repository: sl(),
      ));

  // Repository
  sl.registerLazySingleton<FinancialRepository>(
    () => FinancialRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Source
  sl.registerLazySingleton<FinancialRemoteDataSource>(
    () => FinancialRemoteDataSourceImpl(
      apiClient: sl(),
    ),
  );
}

void _initNotificationChannels() {
  // Data Source
  sl.registerLazySingleton<NotificationChannelsRemoteDataSource>(
    () => NotificationChannelsRemoteDataSource(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<INotificationChannelsRepository>(
    () => NotificationChannelsRepositoryImpl(remote: sl()),
  );

  // Bloc
  sl.registerFactory<ChannelsBloc>(
    () => ChannelsBloc(repository: sl()),
  );
}
