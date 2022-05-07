import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lotus_pollen/home/home_page.dart';
import 'package:lotus_pollen/providers.dart';
import 'package:lotus_pollen/send/send_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferencesProvider = Provider<SharedPreferences>(
    (ref) => sharedPreferences,
  );
  runApp(const ProviderScope(child: Pollen()));
}

class Pollen extends StatelessWidget {
  const Pollen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pollen',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => const HomePage(),
        '/send': (context) => const SendPage(),
      },
    );
  }
}
