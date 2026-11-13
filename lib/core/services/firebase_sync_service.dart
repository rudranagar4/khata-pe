import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class FirebaseSyncService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static const String projectId = 'khata-pe';
  static const String projectNumber = '657069485194';

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
      // Non-blocking fire-and-forget cloud write so UI never hangs
      firestore!
          .collection(collection)
          .doc(id)
          .set(data, SetOptions(merge: true))
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
      // Non-blocking fire-and-forget cloud delete so UI never hangs
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
}

