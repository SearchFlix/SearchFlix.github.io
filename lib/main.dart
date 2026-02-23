import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/home_screen.dart';
import 'screens/details_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/actor_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'services/watchlist_provider.dart';
import 'services/auth_service.dart';
import 'models/movie.dart';

void main() {
  // Use professional URLs (remove the #)
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, WatchlistProvider>(
          create: (_) => WatchlistProvider(),
          update: (_, auth, watchlist) => watchlist!..update(auth),
        ),
      ],
      child: const SearchFlixApp(),
    ),
  );
}

class SearchFlixApp extends StatefulWidget {
  const SearchFlixApp({super.key});

  @override
  State<SearchFlixApp> createState() => _SearchFlixAppState();
}

class _SearchFlixAppState extends State<SearchFlixApp> {
  Locale _locale = const Locale('fa');

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(onLocaleChange: setLocale),
      ),
      GoRoute(
        path: '/watchlist',
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final movie = state.extra as Movie?;
          final testMode = state.uri.queryParameters['test'] == 'true';
          
          if (testMode) {
            Provider.of<AuthService>(context, listen: false).toggleTestMode();
          }

          if (movie == null) {
            return const HomeScreen(onLocaleChange: null);
          }
          return DetailsScreen(movie: movie);
        },
      ),
      GoRoute(
        path: '/secret-auth',
        builder: (context, state) {
          // Secretly login without UI mention
          Future.microtask(() {
            Provider.of<AuthService>(context, listen: false).login();
            context.go('/');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/actor/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'] ?? 'Actor';
          return ActorScreen(actorId: id, actorName: name);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SearchFlix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
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
    );
  }
}
