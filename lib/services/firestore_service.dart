import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _userCol {
    final uid = _uid;
    if (uid == null) {
      throw Exception("Kullanıcı oturumu yok.");
    }
    return _firestore.collection('users').doc(uid).collection('portfolio');
  }

  String _docKey(AssetType type, String symbol) =>
      "${type.persistValue}_${symbol.trim().toUpperCase()}";

  Future<void> addAsset(AssetModel asset) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final docRef = _userCol.doc(_docKey(asset.type, asset.symbol));
      await docRef.set(asset.toMap(), SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print("Firestore ekleme hatası: $e");
    }
  }

  Stream<List<AssetModel>> getPortfolioStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .snapshots()
          .map((snap) {
        return snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return AssetModel.fromMap(data);
        }).toList();
      });
    });
  }

  Future<void> deleteAsset({
    required AssetType type,
    required String symbol,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final q = await _userCol
          .where('symbol', isEqualTo: symbol.trim().toUpperCase())
          .where('type', isEqualTo: type.persistValue)
          .get();

      final batch = _firestore.batch();
      for (final doc in q.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Silme hatası: $e");
    }
  }

  Future<void> deleteById(String docId) async {
    final uid = _uid;
    if (uid == null) return;
    await _userCol.doc(docId).delete();
  }

  Future<void> upsertAsset({
    required AssetType type,
    required String symbol,
    required String name,
    required double quantity,
    required double buyPrice,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final sym = symbol.trim().toUpperCase();
    final docRef = _userCol.doc(_docKey(type, sym));

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (!snap.exists) {
        tx.set(docRef, {
          "symbol": sym,
          "name": name.trim().isEmpty ? sym : name.trim(),
          "type": type.persistValue,
          "quantity": quantity,
          "avgCost": buyPrice,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snap.data() ?? {};
      final curQty = ((data["quantity"] ?? 0) as num).toDouble();
      final curAvg = ((data["avgCost"] ?? 0) as num).toDouble();

      final newQty = curQty + quantity;
      final newAvg = newQty <= 0
          ? 0
          : ((curAvg * curQty) + (buyPrice * quantity)) / newQty;

      tx.set(
        docRef,
        {
          "quantity": newQty,
          "avgCost": newAvg,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<String> getUserName() async {
    final uid = _uid;
    if (uid == null) return "Misafir";
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return "Kullanıcı";
    return (doc.data()?['name'] ?? "Kullanıcı").toString();
  }

  Future<void> normalizePortfolio() async {
    final uid = _uid;
    if (uid == null) return;

    final snap = await _userCol.get();
    if (snap.docs.isEmpty) return;

    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in snap.docs) {
      final data = d.data();
      final sym = (data["symbol"] ?? "").toString().trim().toUpperCase();
      final typeStr = (data["type"] ?? "").toString();
      if (sym.isEmpty) continue;
      final key = "${typeStr}_$sym";
      grouped.putIfAbsent(key, () => []).add(d);
    }

    final batch = _firestore.batch();

    for (final entry in grouped.entries) {
      final docs = entry.value;
      if (docs.length == 1 && docs.first.id == entry.key) continue;

      double totalQty = 0, totalCost = 0;
      String symbol = "", name = "", typeStr = "stock";

      for (final d in docs) {
        final data = d.data();
        symbol = (data["symbol"] ?? symbol).toString();
        name = (data["name"] ?? name).toString();
        typeStr = (data["type"] ?? typeStr).toString();

        final q = ((data["quantity"] ?? 0) as num).toDouble();
        final avg = ((data["avgCost"] ?? 0) as num).toDouble();

        totalQty += q;
        totalCost += (q * avg);
      }

      final avgCost = totalQty <= 0 ? 0 : totalCost / totalQty;
      final canonicalRef = _userCol.doc(entry.key);

      batch.set(
        canonicalRef,
        {
          "symbol": symbol,
          "name": name.isEmpty ? symbol : name,
          "type": typeStr,
          "quantity": totalQty,
          "avgCost": avgCost,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final d in docs) {
        if (d.id != entry.key) batch.delete(d.reference);
      }
    }

    await batch.commit();
  }
}
