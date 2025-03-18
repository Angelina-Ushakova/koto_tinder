class Cat {
  final String id;
  final String url;
  final List<Breed>? breeds;

  Cat({required this.id, required this.url, this.breeds});

  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'],
      url: json['url'],
      breeds:
      json['breeds'] != null
          ? List<Breed>.from(json['breeds'].map((x) => Breed.fromJson(x)))
          : null,
    );
  }
}

class Breed {
  final String id;
  final String name;
  final String? description;
  final String? temperament;
  final String? origin;
  final String? lifeSpan;
  final String? wikipediaUrl;

  Breed({
    required this.id,
    required this.name,
    this.description,
    this.temperament,
    this.origin,
    this.lifeSpan,
    this.wikipediaUrl,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      temperament: json['temperament'],
      origin: json['origin'],
      lifeSpan: json['life_span'],
      wikipediaUrl: json['wikipedia_url'],
    );
  }
}
