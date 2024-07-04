import 'package:flutter/material.dart';
import 'crypto.dart';
import 'crypto_service.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(CryptoApp());
}

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Prices',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CryptoListScreen(),
    );
  }
}

class CryptoListScreen extends StatefulWidget {
  @override
  _CryptoListScreenState createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  late Future<List<Crypto>> futureCryptos;
  final CryptoService cryptoService = CryptoService();

  @override
  void initState() {
    super.initState();
    futureCryptos = cryptoService.fetchCryptos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Prices'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Today: ${DateFormat.yMMMd().format(DateTime.now())}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Crypto>>(
              future: futureCryptos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final cryptos = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: cryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = cryptos[index];
                      return Card(
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                crypto.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(crypto.symbol),
                              SizedBox(height: 8.0),
                              Text('\$${crypto.priceUsd.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
