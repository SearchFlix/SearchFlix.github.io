import 'package:flutter/material.dart';

class Lang {
  final String trending;
  final String searchHint;
  final String movieDetails;
  final String watchlist;
  final String language;
  final String login;
  final String register;
  final String optional;
  final String surpriseMe;
  final String releaseDate;
  final String rating;
  final String emptyWatchlist;
  final String clearAll;
  final String itemsCount;
  final String exploreNow;

  Lang({
    required this.trending,
    required this.searchHint,
    required this.movieDetails,
    required this.watchlist,
    required this.language,
    required this.login,
    required this.register,
    required this.optional,
    required this.surpriseMe,
    required this.releaseDate,
    required this.rating,
    required this.emptyWatchlist,
    required this.clearAll,
    required this.itemsCount,
    required this.exploreNow,
  });

  static Map<String, Lang> _translations = {
    'fa': Lang(
      trending: 'داغ‌ترین‌ها',
      searchHint: 'جستجوی فیلم...',
      movieDetails: 'جزئیات فیلم',
      watchlist: 'لیست تماشا',
      language: 'زبان',
      login: 'ورود',
      register: 'ثبت نام',
      optional: 'اختیاری',
      surpriseMe: 'غافلگیری!',
      releaseDate: 'تاریخ انتشار',
      rating: 'امتیاز',
      emptyWatchlist: 'لیست تماشای شما خالی است',
      clearAll: 'پاکسازی همه',
      itemsCount: 'مورد',
      exploreNow: 'همین حالا بگردیم!',
    ),
    'en': Lang(
      trending: 'Trending Now',
      searchHint: 'Search movies...',
      movieDetails: 'Movie Details',
      watchlist: 'Watchlist',
      language: 'Language',
      login: 'Login',
      register: 'Register',
      optional: 'Optional',
      surpriseMe: 'Surprise Me!',
      releaseDate: 'Release Date',
      rating: 'Rating',
      emptyWatchlist: 'Your watchlist is empty',
      clearAll: 'Clear All',
      itemsCount: 'Items',
      exploreNow: 'Let\'s Explore!',
    ),
    'ar': Lang(
      trending: 'الأكثر رواجاً',
      searchHint: 'البحث عن الأفلام...',
      movieDetails: 'تفاصيل الفيلم',
      watchlist: 'قائمة المشاهدة',
      language: 'اللغة',
      login: 'تسجيل الدخول',
      register: 'تسجيل',
      optional: 'اختياري',
      surpriseMe: 'فاجئني!',
      releaseDate: 'تاريخ الإصدار',
      rating: 'التقييم',
    ),
    'es': Lang(
      trending: 'Tendencias',
      searchHint: 'Buscar películas...',
      movieDetails: 'Detalles de la película',
      watchlist: 'Lista de seguimiento',
      language: 'Idioma',
      login: 'Iniciar sesión',
      register: 'Registrarse',
      optional: 'Opcional',
      surpriseMe: '¡Sorpréndeme!',
      releaseDate: 'Fecha de lanzamiento',
      rating: 'Calificación',
    ),
    'fr': Lang(
      trending: 'Tendances',
      searchHint: 'Rechercher des films...',
      movieDetails: 'Détails du film',
      watchlist: 'Liste de surveillance',
      language: 'Langue',
      login: 'Connexion',
      register: 'S\'inscrire',
      optional: 'Optionnel',
      surpriseMe: 'Surprends-moi !',
      releaseDate: 'Date de sortie',
      rating: 'Note',
    ),
  };

  static Lang of(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    return _translations[locale.languageCode] ?? _translations['en']!;
  }

  String get currentLocale => 'en'; // Placeholder
}
