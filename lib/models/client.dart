class Client {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final int isSynced;

  Client({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    required this.createdAt,
    this.isSynced = 0,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['created_at'] ?? map['crea'];
    if (rawDate != null) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final rawLat = map['lat'];
    final rawLng = map['lng'];

    return Client(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Unnamed').toString(),
      lat: (rawLat is num) ? rawLat.toDouble() : double.tryParse(rawLat?.toString() ?? ''),
      lng: (rawLng is num) ? rawLng.toDouble() : double.tryParse(rawLng?.toString() ?? ''),
      createdAt: parsedDate,
      isSynced: (map['is_synced'] is num) ? (map['is_synced'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  @override
  String toString() =>
      'Client(id: $id, name: $name, lat: $lat, lng: $lng, created_at: $createdAt, is_synced: $isSynced)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
