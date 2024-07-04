import 'package:flutter/material.dart';
import 'crypto.dart';
import 'crypto_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CryptoApp());
}

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Crypto Prices',
            theme: themeProvider.getTheme(),
            home: CryptoListScreen(),
          );
        },
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  ThemeData getTheme() {
    return isDarkMode ? ThemeData.dark() : ThemeData.light();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}

class CryptoListScreen extends StatefulWidget {
  @override
  _CryptoListScreenState createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  late Future<List<Crypto>> futureCryptos;
  final CryptoService cryptoService = CryptoService();
  late Timer timer;
  String currentTime = '';

  @override
  void initState() {
    super.initState();
    futureCryptos = cryptoService.fetchCryptos();
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _getCurrentTime());
  }

  void _getCurrentTime() {
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 7));
    final String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    setState(() {
      currentTime = formattedDateTime;
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Prices'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Jakarta Time: $currentTime',
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
                      return GestureDetector(
                        onTap: () => _showCryptoDetails(context, crypto),
                        child: Card(
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
                                FutureBuilder<double>(
                                  future: _convertToIDR(crypto.priceUsd),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('Loading...');
                                    } else if (snapshot.hasError) {
                                      return Text('Error');
                                    } else if (snapshot.hasData) {
                                      final formatter = NumberFormat.currency(
                                          locale: 'id',
                                          symbol: 'Rp ',
                                          decimalDigits: 0);
                                      return Text(
                                          formatter.format(snapshot.data));
                                    } else {
                                      return Text('N/A');
                                    }
                                  },
                                ),
                                Text('\$${crypto.priceUsd.toStringAsFixed(2)}'),
                              ],
                            ),
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

  Future<void> _showCryptoDetails(BuildContext context, Crypto crypto) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(crypto.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Symbol: ${crypto.symbol}'),
              Text('Price USD: \$${crypto.priceUsd.toStringAsFixed(2)}'),
              FutureBuilder<double>(
                future: _convertToIDR(crypto.priceUsd),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...');
                  } else if (snapshot.hasError) {
                    return Text('Error');
                  } else if (snapshot.hasData) {
                    final formatter = NumberFormat.currency(
                        locale: 'id', symbol: 'Rp ', decimalDigits: 0);
                    return Text(
                        'Price IDR: ${formatter.format(snapshot.data)}');
                  } else {
                    return Text('N/A');
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<double> _convertToIDR(double priceUsd) async {
    final response = await http
        .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final double rate = data['rates']['IDR'];
      return priceUsd * rate;
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }
}
