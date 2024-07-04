class Crypto {
  final String name;
  final String symbol;
  final double priceUsd;

  Crypto({required this.name, required this.symbol, required this.priceUsd});

  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      name: json['name'] ?? 'Unknown',
      symbol: json['symbol'] ?? 'Unknown',
      priceUsd: double.tryParse(json['price_usd']?.toString() ?? '0') ?? 0.0,
    );
  }
}
