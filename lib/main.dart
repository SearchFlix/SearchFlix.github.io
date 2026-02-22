import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SearchFlixApp());
}

class SearchFlixApp extends StatefulWidget {
  const SearchFlixApp({super.key});

  @override
  State<SearchFlixApp> createState() => _SearchFlixAppState();
}

class _SearchFlixAppState extends State<SearchFlixApp> {
  Locale _locale = const Locale('fa'); // Default to Persian as requested

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SearchFlix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('fr'),
      ],
      home: HomeScreen(onLocaleChange: setLocale),
    );
  }
}
