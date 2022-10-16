class Crime {
  final String category;
  final String latitude;
  final String longitude;

  const Crime({
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  factory Crime.fromJson(Map<String, dynamic> json) {
    return Crime(
        category: json['category'],
        latitude: json['location']['latitude'],
        longitude: json['location']['longitude']);
  }
}
