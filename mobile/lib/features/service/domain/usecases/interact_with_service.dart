import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/service_repository.dart';

/// Use case for interacting with a service (like, save, share)
class InteractWithService {
  final ServiceRepository repository;

  InteractWithService(this.repository);

  Future<Either<Failure, ServiceInteractionResponse>> call(String serviceId, String interactionType) async {
    if (serviceId.isEmpty) {
      return const Left(ValidationFailure('Service ID cannot be empty'));
    }

    if (interactionType.isEmpty) {
      return const Left(ValidationFailure('Interaction type cannot be empty'));
    }

    final validTypes = ['like', 'save', 'share'];
    if (!validTypes.contains(interactionType.toLowerCase())) {
      return Left(ValidationFailure('Invalid interaction type. Must be: ${validTypes.join(", ")}'));
    }

    return await repository.interactWithService(serviceId, interactionType.toLowerCase());
  }
}
