import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetAvailableUsersUseCase implements UseCase<List<ChatUser>, GetAvailableUsersParams> {
  final ChatRepository repository;

  GetAvailableUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatUser>>> call(GetAvailableUsersParams params) async {
    return await repository.getAvailableUsers(
      userType: params.userType,
      propertyId: params.propertyId,
    );
  }
}

class GetAvailableUsersParams extends Equatable {
  final String? userType;
  final String? propertyId;

  const GetAvailableUsersParams({
    this.userType,
    this.propertyId,
  });

  @override
  List<Object?> get props => [userType, propertyId];
}