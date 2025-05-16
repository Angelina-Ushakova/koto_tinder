class Cat {
  final String id;
  final String url;
  final List<Breed>? breeds;
  final DateTime? likedAt; // Добавляем поле для хранения времени лайка

  Cat({required this.id, required this.url, this.breeds, this.likedAt});

  // Создаем копию объекта с новым значением времени лайка
  Cat copyWith({DateTime? likedAt}) {
    return Cat(
      id: id,
      url: url,
      breeds: breeds,
      likedAt: likedAt ?? this.likedAt,
    );
  }

  // Фабричный метод для создания объекта из JSON
  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'],
      url: json['url'],
      breeds:
          json['breeds'] != null
              ? List<Breed>.from(json['breeds'].map((x) => Breed.fromJson(x)))
              : null,
      likedAt: json['likedAt'] != null ? DateTime.parse(json['likedAt']) : null,
    );
  }

  // Метод для преобразования объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'breeds': breeds?.map((x) => x.toJson()).toList(),
      'likedAt': likedAt?.toIso8601String(),
    };
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

  // Метод для преобразования объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'temperament': temperament,
      'origin': origin,
      'life_span': lifeSpan,
      'wikipedia_url': wikipediaUrl,
    };
  }
}
