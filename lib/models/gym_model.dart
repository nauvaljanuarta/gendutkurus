class Gym {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String address;
  final String distance;
  final String openHours;
  final List<String> facilities;
  final String description;
  final bool isFavorite;
  final String category;

  const Gym({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.address,
    required this.distance,
    required this.openHours,
    required this.facilities,
    required this.description,
    required this.isFavorite,
    required this.category,
  });
}
