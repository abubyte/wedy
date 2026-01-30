import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/gallery_image.dart';
import '../../domain/usecases/get_gallery_images.dart';
import '../../domain/usecases/add_gallery_image.dart';
import '../../domain/usecases/remove_gallery_image.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

/// BLoC for managing merchant gallery
class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GetGalleryImages _getGalleryImages;
  final AddGalleryImage _addGalleryImage;
  final RemoveGalleryImage _removeGalleryImage;

  GalleryBloc({
    required GetGalleryImages getGalleryImages,
    required AddGalleryImage addGalleryImage,
    required RemoveGalleryImage removeGalleryImage,
  }) : _getGalleryImages = getGalleryImages,
       _addGalleryImage = addGalleryImage,
       _removeGalleryImage = removeGalleryImage,
       super(const GalleryInitial()) {
    on<LoadGalleryEvent>(_onLoadGallery);
    on<AddGalleryImageEvent>(_onAddGalleryImage);
    on<RemoveGalleryImageEvent>(_onRemoveGalleryImage);
    on<RefreshGalleryEvent>(_onRefreshGallery);
  }

  /// Get current images from state if available
  List<GalleryImage>? get _currentImages {
    final currentState = state;
    if (currentState is GalleryLoaded) {
      return currentState.images;
    }
    if (currentState is GalleryLoading) {
      return currentState.previousImages;
    }
    if (currentState is GalleryError) {
      return currentState.previousImages;
    }
    return null;
  }

  /// Map failure to error type
  GalleryErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => GalleryErrorType.network,
      ServerFailure() => GalleryErrorType.server,
      AuthFailure() => GalleryErrorType.auth,
      NotFoundFailure() => GalleryErrorType.notFound,
      ValidationFailure() => GalleryErrorType.tariffLimit,
      CacheFailure() => GalleryErrorType.unknown,
    };
  }

  Future<void> _onLoadGallery(LoadGalleryEvent event, Emitter<GalleryState> emit) async {
    emit(GalleryLoading(type: GalleryLoadingType.initial, previousImages: _currentImages));

    final result = await _getGalleryImages();

    result.fold(
      (failure) => emit(
        GalleryError(
          failure.toUserMessage(entityName: 'Gallery'),
          type: _mapFailureToErrorType(failure),
          previousImages: _currentImages,
        ),
      ),
      (images) => emit(GalleryLoaded(GalleryData(images: images))),
    );
  }

  Future<void> _onAddGalleryImage(AddGalleryImageEvent event, Emitter<GalleryState> emit) async {
    final previousImages = _currentImages;

    emit(GalleryLoading(type: GalleryLoadingType.adding, previousImages: previousImages));

    final result = await _addGalleryImage(file: event.file, displayOrder: event.displayOrder);

    result.fold(
      (failure) => emit(
        GalleryError(
          failure.toUserMessage(entityName: 'Gallery image'),
          type: _mapFailureToErrorType(failure),
          previousImages: previousImages,
        ),
      ),
      (uploadResult) {
        if (uploadResult.success && uploadResult.imageId != null && uploadResult.s3Url != null) {
          // Create a new gallery image from the upload result
          final newImage = GalleryImage(
            id: uploadResult.imageId!,
            s3Url: uploadResult.s3Url!,
            fileName: event.file.path.split('/').last,
            displayOrder: event.displayOrder,
            createdAt: DateTime.now(),
          );

          final newData = GalleryData(
            images: [...(previousImages ?? []), newImage],
            lastOperation: ImageAddedOperation(imageId: uploadResult.imageId!, s3Url: uploadResult.s3Url!),
          );
          emit(GalleryLoaded(newData));
        } else {
          emit(GalleryError(uploadResult.message, type: GalleryErrorType.server, previousImages: previousImages));
        }
      },
    );
  }

  Future<void> _onRemoveGalleryImage(RemoveGalleryImageEvent event, Emitter<GalleryState> emit) async {
    final previousImages = _currentImages;

    emit(GalleryLoading(type: GalleryLoadingType.removing, previousImages: previousImages));

    final result = await _removeGalleryImage(event.imageId);

    result.fold(
      (failure) => emit(
        GalleryError(
          failure.toUserMessage(entityName: 'Gallery image'),
          type: _mapFailureToErrorType(failure),
          previousImages: previousImages,
        ),
      ),
      (_) {
        final newData = GalleryData(
          images: (previousImages ?? []).where((i) => i.id != event.imageId).toList(),
          lastOperation: ImageRemovedOperation(event.imageId),
        );
        emit(GalleryLoaded(newData));
      },
    );
  }

  Future<void> _onRefreshGallery(RefreshGalleryEvent event, Emitter<GalleryState> emit) async {
    add(const LoadGalleryEvent());
  }
}
