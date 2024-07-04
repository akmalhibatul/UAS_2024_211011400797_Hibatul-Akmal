import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crypto.dart';

class CryptoService {
  static const String url = 'https://api.coinlore.net/api/tickers/';

  Future<List<Crypto>> fetchCryptos() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> cryptoJson = data['data'] ?? [];
      return cryptoJson.map((json) => Crypto.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load crypto data');
    }
  }
}
