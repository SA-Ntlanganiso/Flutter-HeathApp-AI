class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final double distance; // in km
  final String imageUrl;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.distance,
    required this.imageUrl,
  });
}