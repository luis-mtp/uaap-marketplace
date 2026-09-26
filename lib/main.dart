import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uaap_market/pages/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://metznmlrnejctdmjyqlz.supabase.co',
    publishableKey: 'sb_publishable_eXQRJLzsx7WnvY0OVgat2Q_Sms_uYN2',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UAAP Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 27, 25, 23),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}