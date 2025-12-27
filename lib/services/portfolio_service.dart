import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _uid;
    return _db.collection('users').doc(uid).collection('portfolio');
  }

  Future<void> addAsset({
    required String symbol,
    required String name,
    required String type,
    required double amount,
    required double buyPrice,
  }) async {
    if (_uid == null) return;

    final docId = "$type:$symbol";

    await _col().doc(docId).set({
      "symbol": symbol,
      "name": name,
      "type": type,
      "amount": amount,
      "buyPrice": buyPrice,
      "addedAt": DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAssetByDocId(String docId) async {
    if (_uid == null) return;
    await _col().doc(docId).delete();
  }

  Future<List<Map<String, dynamic>>> getPortfolio() async {
    if (_uid == null) return [];
    final snap = await _col().orderBy("addedAt", descending: true).get();

    return snap.docs.map((d) {
      final data = d.data();
      data["_docId"] = d.id; 
      return data;
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchPortfolio() {
    if (_uid == null) return const Stream.empty();

    return _col().orderBy("addedAt", descending: true).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data["_docId"] = d.id; 
        return data;
      }).toList();
    });
  }
}
