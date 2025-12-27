class StockModel {
  final String symbol;     
  final String name;        
  final double price;      
  final double changeRate; 

  StockModel({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changeRate,
  });
}