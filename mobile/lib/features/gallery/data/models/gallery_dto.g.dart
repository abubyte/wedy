// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryImageDto _$GalleryImageDtoFromJson(Map<String, dynamic> json) => GalleryImageDto(
  id: json['id'] as String,
  s3Url: json['s3_url'] as String,
  fileName: json['file_name'] as String,
  fileSize: (json['file_size'] as num?)?.toInt(),
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$GalleryImageDtoToJson(GalleryImageDto instance) => <String, dynamic>{
  'id': instance.id,
  's3_url': instance.s3Url,
  'file_name': instance.fileName,
  'file_size': instance.fileSize,
  'display_order': instance.displayOrder,
  'created_at': instance.createdAt,
};

ImageUploadResponseDto _$ImageUploadResponseDtoFromJson(Map<String, dynamic> json) => ImageUploadResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  imageId: json['image_id'] as String?,
  s3Url: json['s3_url'] as String?,
  presignedUrl: json['presigned_url'] as String?,
);

Map<String, dynamic> _$ImageUploadResponseDtoToJson(ImageUploadResponseDto instance) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'image_id': instance.imageId,
  's3_url': instance.s3Url,
  'presigned_url': instance.presignedUrl,
};
