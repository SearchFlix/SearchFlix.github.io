class DownloadSource {
  final int id;
  final String quality;
  final String type;
  final String url;

  DownloadSource({
    required this.id,
    required this.quality,
    required this.type,
    required this.url,
  });

  factory DownloadSource.fromJson(Map<String, dynamic> json) {
    return DownloadSource(
      id: json['id'],
      quality: json['quality'] ?? 'Unknown',
      type: json['type'] ?? 'Download',
      url: json['url'] ?? '',
    );
  }
}

class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String mediaType;
  List<DownloadSource>? sources;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    this.mediaType = 'movie',
    this.sources,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'No Title',
      overview: json['overview'] ?? 'No description available.',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? 'Unknown',
      mediaType: json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'media_type': mediaType,
    };
  }

  String get posterUrl => posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : 'https://via.placeholder.com/500x750?text=No+Poster';
  String get backdropUrl => backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : posterUrl;
}

