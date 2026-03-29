import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Holds the initialized StorageService singleton.
/// Initialize via [initStorageProvider] before using.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('Call initStorageProvider first'),
);
