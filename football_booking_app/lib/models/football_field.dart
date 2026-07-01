class FootballField {
  final String id;
  final String name;
  final String? address;
  final String? imageUrl;
  final double? pricePerHour;

  FootballField({
    required this.id,
    required this.name,
    this.address,
    this.imageUrl,
    this.pricePerHour,
  });

  factory FootballField.fromJson(Map<String, dynamic> json) {
    return FootballField(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      imageUrl: json['image_url'],
      pricePerHour: json['price_per_hour']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'image_url': imageUrl,
      'price_per_hour': pricePerHour,
    };
  }
}
