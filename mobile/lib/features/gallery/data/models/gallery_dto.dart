import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/gallery_image.dart';

part 'gallery_dto.g.dart';

/// Gallery image DTO
@JsonSerializable()
class GalleryImageDto {
  final String id;
  @JsonKey(name: 's3_url')
  final String s3Url;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final String createdAt;

  GalleryImageDto({
    required this.id,
    required this.s3Url,
    required this.fileName,
    this.fileSize,
    required this.displayOrder,
    required this.createdAt,
  });

  factory GalleryImageDto.fromJson(Map<String, dynamic> json) => _$GalleryImageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GalleryImageDtoToJson(this);

  GalleryImage toEntity() {
    return GalleryImage(
      id: id,
      s3Url: s3Url,
      fileName: fileName,
      fileSize: fileSize,
      displayOrder: displayOrder,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

/// Image upload response DTO
@JsonSerializable()
class ImageUploadResponseDto {
  final bool success;
  final String message;
  @JsonKey(name: 'image_id')
  final String? imageId;
  @JsonKey(name: 's3_url')
  final String? s3Url;
  @JsonKey(name: 'presigned_url')
  final String? presignedUrl;

  ImageUploadResponseDto({required this.success, required this.message, this.imageId, this.s3Url, this.presignedUrl});

  factory ImageUploadResponseDto.fromJson(Map<String, dynamic> json) => _$ImageUploadResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ImageUploadResponseDtoToJson(this);

  ImageUploadResult toEntity() {
    return ImageUploadResult(
      success: success,
      message: message,
      imageId: imageId,
      s3Url: s3Url,
      presignedUrl: presignedUrl,
    );
  }
}
