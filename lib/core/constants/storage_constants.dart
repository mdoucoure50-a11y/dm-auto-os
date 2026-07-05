import '../config/env_config.dart';

/// Supabase Storage bucket names and upload constraints.
abstract final class StorageConstants {
  static String get documentsBucket => EnvConfig.storageDocumentsBucket;
  static String get vehiclePhotosBucket => EnvConfig.storageVehiclePhotosBucket;

  static const int maxDocumentSizeBytes = 52_428_800; // 50 MB
  static const int maxPhotoSizeBytes = 10_485_760; // 10 MB

  static const List<String> allowedDocumentMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  static const List<String> allowedPhotoMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Builds a storage path: `{entityType}/{entityId}/{fileName}`
  static String buildPath({
    required String entityType,
    required String entityId,
    required String fileName,
  }) => '$entityType/$entityId/$fileName';
}
