import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/storage_constants.dart';
import '../../core/errors/app_exception.dart';
import 'supabase_service.dart';

/// Upload and manage files in Supabase Storage.
class SupabaseStorageService {
  const SupabaseStorageService();

  StorageFileApi _bucket(String bucket) {
    if (!SupabaseService.isConnected) {
      throw const NetworkException('Storage requires Supabase connection');
    }
    return SupabaseService.storage.from(bucket);
  }

  /// Uploads a document file and returns the storage path.
  Future<String> uploadDocument({
    required String entityType,
    required String entityId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final path = StorageConstants.buildPath(
      entityType: entityType,
      entityId: entityId,
      fileName: fileName,
    );

    if (bytes.length > StorageConstants.maxDocumentSizeBytes) {
      throw const ValidationException('File exceeds maximum size of 50 MB');
    }

    return SupabaseService.execute(() async {
      await _bucket(StorageConstants.documentsBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
      return path;
    }, errorMessage: 'Failed to upload document');
  }

  /// Uploads a vehicle photo and returns the storage path.
  Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final path = StorageConstants.buildPath(
      entityType: 'vehicles',
      entityId: vehicleId,
      fileName: fileName,
    );

    if (bytes.length > StorageConstants.maxPhotoSizeBytes) {
      throw const ValidationException('Photo exceeds maximum size of 10 MB');
    }

    return SupabaseService.execute(() async {
      await _bucket(StorageConstants.vehiclePhotosBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      return path;
    }, errorMessage: 'Failed to upload vehicle photo');
  }

  /// Creates a time-limited signed URL for private file access.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    return SupabaseService.execute(() async {
      return _bucket(bucket).createSignedUrl(path, expiresInSeconds);
    }, errorMessage: 'Failed to create signed URL');
  }

  /// Removes a file from storage.
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await SupabaseService.execute(() async {
      await _bucket(bucket).remove([path]);
    }, errorMessage: 'Failed to delete file');
  }
}
