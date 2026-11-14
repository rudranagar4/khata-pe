import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class FirebaseSyncService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static const String projectId = 'khata-pe';
  static const String projectNumber = '657069485194';

  static String _activeUserId = 'owner_advanilnagar';
  static void setActiveUser(String userId) {
    if (userId.isNotEmpty) {
      _activeUserId = userId;
    }
  }

  static String get activeUserId => _activeUserId;

  static FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Firebase using Khata Pe credentials
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 8));
      }
      _isInitialized = true;
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (_) {}
      debugPrint('Firebase initialized for project: $projectId ($projectNumber)');
    } catch (e) {
      debugPrint('Firebase init fallback: $e');
    }
  }

  static Future<void> _writeDoc(String collection, String id, Map<String, dynamic> data) async {
    if (!_isInitialized || firestore == null || id.isEmpty) return;
    try {
      final docData = Map<String, dynamic>.from(data);
      docData['userId'] = _activeUserId;
      docData['updatedAt'] = DateTime.now().toIso8601String();

      // Dual-write: write to user-scoped subcollection AND top-level collection
      // 1. User-scoped path: users/{userId}/{collection}/{id}
      firestore!
          .collection('users')
          .doc(_activeUserId)
          .collection(collection)
          .doc(id)
          .set(docData, SetOptions(merge: true))
          .catchError((e) {
        debugPrint('Firestore write users/$_activeUserId/$collection/$id error: $e');
      });

      // 2. Global path: {collection}/{id}
      firestore!
          .collection(collection)
          .doc(id)
          .set(docData, SetOptions(merge: true))
          .catchError((e) {
        debugPrint('Firestore write $collection/$id error: $e');
      });
    } catch (e) {
      debugPrint('Firestore write $collection/$id error: $e');
    }
  }

  static Future<void> _deleteDoc(String collection, String id) async {
    if (!_isInitialized || firestore == null || id.isEmpty) return;
    try {
      // 1. Delete from user-scoped collection
      firestore!
          .collection('users')
          .doc(_activeUserId)
          .collection(collection)
          .doc(id)
          .delete()
          .catchError((e) {
        debugPrint('Firestore delete users/$_activeUserId/$collection/$id error: $e');
      });

      // 2. Delete from global collection
      firestore!
          .collection(collection)
          .doc(id)
          .delete()
          .catchError((e) {
        debugPrint('Firestore delete $collection/$id error: $e');
      });
    } catch (e) {
      debugPrint('Firestore delete $collection/$id error: $e');
    }
  }

  // --- Properties Firestore Sync ---
  static Future<void> syncProperty(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await _writeDoc('properties', id, data);
  }

  static Future<void> deleteProperty(String propertyId) async {
    await _deleteDoc('properties', propertyId);
  }

  // --- Tenants Firestore Sync ---
  static Future<void> syncTenant(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await _writeDoc('tenants', id, data);
  }

  static Future<void> deleteTenant(String tenantId) async {
    await _deleteDoc('tenants', tenantId);
  }

  // --- Rent Ledger Firestore Sync ---
  static Future<void> syncRentEntry(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await _writeDoc('rent_entries', id, data);
  }

  static Future<void> deleteRentEntry(String entryId) async {
    await _deleteDoc('rent_entries', entryId);
  }

  // --- Expenses Firestore Sync ---
  static Future<void> syncExpense(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await _writeDoc('expenses', id, data);
  }

  static Future<void> deleteExpense(String expenseId) async {
    await _deleteDoc('expenses', expenseId);
  }

  // --- Cloud Fetch (used to restore data on login / app start) ---

  /// Fetches all documents from a Firestore collection for the active user.
  /// Falls back to top-level collection for backwards compatibility.
  /// Returns empty list if Firebase is not initialized or any error occurs.
  static Future<List<Map<String, dynamic>>> fetchAll(String collection, {String? userId}) async {
    if (!_isInitialized || firestore == null) return [];
    final targetUser = userId ?? _activeUserId;
    try {
      // 1. Try user-scoped collection: users/{targetUser}/{collection}
      final userSnap = await firestore!
          .collection('users')
          .doc(targetUser)
          .collection(collection)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));

      if (userSnap.docs.isNotEmpty) {
        return userSnap.docs.map((d) => d.data()).toList();
      }

      // 2. Fallback to top-level collection: {collection}
      final topSnap = await firestore!
          .collection(collection)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));

      return topSnap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Firestore fetchAll $collection error: $e');
      return [];
    }
  }

  /// Bulk pushes all local in-memory data to Firestore
  static Future<int> pushAllLocalData({
    required List<Map<String, dynamic>> properties,
    required List<Map<String, dynamic>> tenants,
    required List<Map<String, dynamic>> rentEntries,
    required List<Map<String, dynamic>> expenses,
  }) async {
    if (!_isInitialized || firestore == null) return 0;
    int syncedCount = 0;
    try {
      for (final p in properties) {
        final id = p['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await _writeDoc('properties', id, p);
          syncedCount++;
        }
      }
      for (final t in tenants) {
        final id = t['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await _writeDoc('tenants', id, t);
          syncedCount++;
        }
      }
      for (final r in rentEntries) {
        final id = r['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await _writeDoc('rent_entries', id, r);
          syncedCount++;
        }
      }
      for (final e in expenses) {
        final id = e['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await _writeDoc('expenses', id, e);
          syncedCount++;
        }
      }
    } catch (e) {
      debugPrint('pushAllLocalData error: $e');
    }
    return syncedCount;
  }
}

