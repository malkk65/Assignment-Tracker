import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles file uploads using Supabase Storage.
///
/// This replaces Firebase Storage to avoid requiring a Blaze billing plan.
/// The rest of the app continues to use Firebase for Auth and Firestore.
class StorageService {
  static const String _bucketName = 'assignments';

  static SupabaseStorageClient get _storage =>
      Supabase.instance.client.storage;

  /// Uploads a file to Supabase Storage and returns a public download URL.
  ///
  /// [file]       — the local file to upload.
  /// [folderPath] — the folder inside the bucket (e.g. 'assignment_files').
  static Future<String> uploadFile(File file, String folderPath) async {
    final fileName = path.basename(file.path);
    final destination =
        '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      final fileBytes = await file.readAsBytes();

      await _storage.from(_bucketName).uploadBinary(
            destination,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      // Get the public URL for the uploaded file
      final publicUrl =
          _storage.from(_bucketName).getPublicUrl(destination);

      if (publicUrl.isEmpty) {
        throw Exception(
          'The file was uploaded but its download link could not be generated. '
          'Please try again.',
        );
      }

      return publicUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '403' || e.statusCode == '401') {
        throw Exception(
          'You are not authorized to upload files. '
          'Please check the storage bucket permissions.',
        );
      }
      if (e.message.contains('Bucket not found')) {
        throw Exception(
          'The storage bucket "$_bucketName" was not found. '
          'Please create it in your Supabase dashboard.',
        );
      }
      throw Exception(
        'Upload failed: ${e.message}. Please try again later.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Something went wrong while uploading your file. '
        'Please check your internet connection and try again.',
      );
    }
  }

  /// Deletes a file from Supabase Storage using its public URL.
  static Future<void> deleteFile(String publicUrl) async {
    try {
      // Extract the path from the URL.
      // Example: .../storage/v1/object/public/assignments/folder/file.pdf
      final Uri uri = Uri.parse(publicUrl);
      final String pathInBucket = uri.pathSegments.last;
      final String folder = uri.pathSegments[uri.pathSegments.length - 2];
      final String fullPath = '$folder/$pathInBucket';

      await _storage.from(_bucketName).remove([fullPath]);
    } catch (e) {
      // We don't want to block the user if file deletion fails, just log it.
      debugPrint('Storage deletion error: $e');
    }
  }
}
