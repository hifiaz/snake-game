import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ular_berbisa/snake.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // unawaited(MobileAds.instance.initialize());
  // Put game into full screen mode on mobile devices.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Lock the game to portrait mode on mobile devices.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ular Berbisa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Color(0xff543310),
        body: SafeArea(child: Snake()),
      ),
    );
  }
}
