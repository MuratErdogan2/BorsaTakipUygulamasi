enum AssetType { stock, currency, fund, crypto }

extension AssetTypeExtension on AssetType {
  String get label {
    switch (this) {
      case AssetType.stock:
        return "Hisse";
      case AssetType.currency:
        return "Döviz";
      case AssetType.fund:
        return "Fon";
      case AssetType.crypto:
        return "Kripto";
    }
  }

  String get persistValue => name;

  static AssetType fromLabel(String label) {
    final x = label.trim().toLowerCase();
    switch (x) {
      case "hisse":
        return AssetType.stock;
      case "döviz":
      case "doviz":
        return AssetType.currency;
      case "fon":
        return AssetType.fund;
      case "kripto":
        return AssetType.crypto;
      default:
        return AssetType.stock;
    }
  }

  static AssetType fromPersist(String v) {
    final x = v.trim().toLowerCase();
    return AssetType.values.firstWhere(
      (t) => t.persistValue == x,
      orElse: () => AssetType.stock,
    );
  }
}

class AssetModel {
  final String symbol;
  final String name;
  final AssetType type;
  final double quantity;
  final double avgCost;
  final DateTime updatedAt;

  AssetModel({
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.avgCost,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        "symbol": symbol.trim().toUpperCase(),
        "name": name.trim().isEmpty ? symbol.trim().toUpperCase() : name.trim(),
        "type": type.persistValue,
        "quantity": quantity,
        "avgCost": avgCost,
        "updatedAt": updatedAt.toIso8601String(),
      };

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      symbol: (map["symbol"] ?? "").toString(),
      name: (map["name"] ?? "").toString(),
      type: AssetTypeExtension.fromPersist((map["type"] ?? "stock").toString()),
      quantity: ((map["quantity"] ?? 0) as num).toDouble(),
      avgCost: ((map["avgCost"] ?? 0) as num).toDouble(),
      updatedAt: DateTime.tryParse((map["updatedAt"] ?? "").toString()) ?? DateTime.now(),
    );
  }
}
