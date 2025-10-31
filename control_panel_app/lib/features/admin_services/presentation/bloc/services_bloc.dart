import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_service_usecase.dart';
import '../../domain/usecases/update_service_usecase.dart';
import '../../domain/usecases/delete_service_usecase.dart';
import '../../domain/usecases/get_services_by_property_usecase.dart';
import '../../domain/usecases/get_service_details_usecase.dart';
import '../../domain/usecases/get_services_by_type_usecase.dart';
import '../../domain/entities/service.dart';
import 'services_event.dart';
import 'services_state.dart';

/// 🎯 BLoC للخدمات
class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final CreateServiceUseCase createServiceUseCase;
  final UpdateServiceUseCase updateServiceUseCase;
  final DeleteServiceUseCase deleteServiceUseCase;
  final GetServicesByPropertyUseCase getServicesByPropertyUseCase;
  final GetServiceDetailsUseCase getServiceDetailsUseCase;
  final GetServicesByTypeUseCase getServicesByTypeUseCase;

  String? _selectedPropertyId;
  String? _currentSearchQuery;
  String? _currentServiceType;

  ServicesBloc({
    required this.createServiceUseCase,
    required this.updateServiceUseCase,
    required this.deleteServiceUseCase,
    required this.getServicesByPropertyUseCase,
    required this.getServiceDetailsUseCase,
    required this.getServicesByTypeUseCase,
  }) : super(ServicesInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadMoreServicesEvent>(_onLoadMoreServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<LoadServiceDetailsEvent>(_onLoadServiceDetails);
    on<SelectPropertyEvent>(_onSelectProperty);
    on<SearchServicesEvent>(_onSearchServices);
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    try {
      if (event.propertyId != null) {
        // Load services by property
        final result = await getServicesByPropertyUseCase(event.propertyId!);
        
        result.fold(
          (failure) => emit(ServicesError(failure.message)),
          (services) {
            final paidServices = services.where((s) => s.price.amount > 0).length;
            emit(ServicesLoaded(
              services: services,
              selectedPropertyId: event.propertyId,
              totalServices: services.length,
              paidServices: paidServices,
            ));
          },
        );
      } else if (event.serviceType != null) {
        // Load services by type
        final result = await getServicesByTypeUseCase(
          GetServicesByTypeParams(
            serviceType: event.serviceType!,
            pageNumber: event.pageNumber,
            pageSize: event.pageSize,
          ),
        );
        _currentServiceType = event.serviceType;
        
        result.fold(
          (failure) => emit(ServicesError(failure.message)),
          (paginatedResult) {
            final paidServices = paginatedResult.items
                .where((s) => s.price.amount > 0)
                .length;
            emit(ServicesLoaded(
              services: paginatedResult.items,
              paginatedServices: paginatedResult,
              totalServices: paginatedResult.totalCount,
              paidServices: paidServices,
              isLoadingMore: false,
            ));
          },
        );
      } else {
        emit(const ServicesLoaded(services: []));
      }
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadMoreServices(
    LoadMoreServicesEvent event,
    Emitter<ServicesState> emit,
  ) async {
    if (state is! ServicesLoaded) return;
    final current = state as ServicesLoaded;
    final page = current.paginatedServices;
    if (page == null || !page.hasNextPage) return;

    // Avoid duplicate triggers
    if (current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));

    final nextPageNumber = page.nextPageNumber ?? (page.pageNumber + 1);
    final result = await getServicesByTypeUseCase(
      GetServicesByTypeParams(
        serviceType: _currentServiceType ?? 'all',
        pageNumber: nextPageNumber,
        pageSize: page.pageSize,
      ),
    );

    result.fold(
      (failure) {
        // Stop loading more but keep existing data
        emit(current.copyWith(isLoadingMore: false));
      },
      (nextPage) {
        // Reliable merge: preserve order and avoid duplicates
        final List<Service> combined = List<Service>.from(current.services);
        final Set<String> seen = combined.map((s) => s.id).toSet();
        for (final s in nextPage.items) {
          if (!seen.contains(s.id)) {
            combined.add(s);
            seen.add(s.id);
          }
        }
        final paidServices = combined.where((s) => s.price.amount > 0).length;

        emit(ServicesLoaded(
          services: combined,
          paginatedServices: nextPage,
          selectedPropertyId: current.selectedPropertyId,
          searchQuery: current.searchQuery,
          totalServices: nextPage.totalCount,
          paidServices: paidServices,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onCreateService(
    CreateServiceEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServiceOperationInProgress());

    final result = await createServiceUseCase(
      CreateServiceParams(
        propertyId: event.propertyId,
        name: event.name,
        price: event.price,
        pricingModel: event.pricingModel,
        icon: event.icon,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (serviceId) {
        emit(const ServiceOperationSuccess('تم إنشاء الخدمة بنجاح'));
        // Reload services for the same property the service was created for
        add(LoadServicesEvent(propertyId: event.propertyId));
      },
    );
  }

  Future<void> _onUpdateService(
    UpdateServiceEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServiceOperationInProgress());

    final result = await updateServiceUseCase(
      UpdateServiceParams(
        serviceId: event.serviceId,
        name: event.name,
        price: event.price,
        pricingModel: event.pricingModel,
        icon: event.icon,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (success) {
        emit(const ServiceOperationSuccess('تم تحديث الخدمة بنجاح'));
        // Reload services
        if (_selectedPropertyId != null) {
          add(LoadServicesEvent(propertyId: _selectedPropertyId));
        }
      },
    );
  }

  Future<void> _onDeleteService(
    DeleteServiceEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesDeleting());

    final result = await deleteServiceUseCase(event.serviceId);

    result.fold(
      (failure) => emit(ServicesDeleteFailed(failure.message)),
      (success) {
        emit(ServicesDeleteSuccess());
        // Reload services
        if (_selectedPropertyId != null) {
          add(LoadServicesEvent(propertyId: _selectedPropertyId));
        }
      },
    );
  }

  Future<void> _onLoadServiceDetails(
    LoadServiceDetailsEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServiceDetailsLoading());

    final result = await getServiceDetailsUseCase(event.serviceId);

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (serviceDetails) => emit(ServiceDetailsLoaded(serviceDetails)),
    );
  }

  Future<void> _onSelectProperty(
    SelectPropertyEvent event,
    Emitter<ServicesState> emit,
  ) async {
    _selectedPropertyId = event.propertyId;
    if (event.propertyId != null) {
      add(LoadServicesEvent(propertyId: event.propertyId));
    } else {
      _currentServiceType = 'all';
      add(const LoadServicesEvent(serviceType: 'all', pageNumber: 1, pageSize: 20));
    }
  }

  Future<void> _onSearchServices(
    SearchServicesEvent event,
    Emitter<ServicesState> emit,
  ) async {
    _currentSearchQuery = event.query;
    
    if (state is ServicesLoaded) {
      final currentState = state as ServicesLoaded;
      
      final filteredServices = currentState.services.where((service) {
        final query = event.query.toLowerCase();
        return service.name.toLowerCase().contains(query) ||
               service.propertyName.toLowerCase().contains(query);
      }).toList();
      
      emit(currentState.copyWith(
        services: filteredServices,
        searchQuery: event.query,
      ));
    }
  }
}