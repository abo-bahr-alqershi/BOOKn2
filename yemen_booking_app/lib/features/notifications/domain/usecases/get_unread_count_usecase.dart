import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class GetUnreadCountUseCase implements UseCase<int, GetUnreadCountParams> {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetUnreadCountParams params) {
    return repository.getUnreadCount();
  }
}

class GetUnreadCountParams extends Equatable {
  const GetUnreadCountParams();

  @override
  List<Object?> get props => [];
}

