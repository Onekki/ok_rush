import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ok_rush/pages/auth/login.dart';
import 'package:ok_rush/pages/auth/reset_pwd.dart';
import 'package:ok_rush/pages/home.dart';
import 'package:ok_rush/pages/splash.dart';
import 'package:ok_rush/pages/starark/starark.dart';
import 'package:ok_rush/pages/starark/starark_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kSupabaseUrl = "https://fnnugvyppqqevbygpdfe.supabase.co";
const kSupabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubnVndnlwcHFxZXZieWdwZGZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDc3Nzk1NDMsImV4cCI6MTk2MzM1NTU0M30.hSZgY1n_GQ3TvGHHKPtPrdF1aEx8jc_O1N_GTsFSVZc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: kSupabaseUrl, anonKey: kSupabaseKey);
  runApp(
    const OkRushApp(),
  );
}

class OkRushApp extends StatelessWidget {
  const OkRushApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/reset_pwd': (_) => const ResetPwdPage(),
        '/starark': (_) => const StarArkPage(),
        '/starark_auth': (_) => const StarArkAuthPage()
      },
    );
  }
}
