class Event {
  final String id;
  final String name;
  final List<String> category;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String city;
  final String venue;
  final String country;
  final String postcode;
  final String address;
  final double latitude;
  final double longitude;
  final String bannerUrl;
  final String status;
  final List<String> genre;
  final String hostName;
  final List<String> lineup;
  final List<String> timeline;
  final int ticketPrice;
  final String ticketsUrl;

  Event(this.id, this.name, this.category, this.description, this.startDateTime, this.endDateTime, this.city, this.venue, this.country, this.postcode, this.address, this.latitude, this.longitude,
      this.bannerUrl, this.status, this.genre, this.hostName, this.lineup, this.timeline, this.ticketPrice, this.ticketsUrl);

  factory Event.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final category = json['category'].cast<String>();
    final description = json['description'];
    final startDateTime = DateTime.parse(json['startDateTime']);
    final endDateTime = DateTime.parse(json['endDateTime']);
    final city = json['city'];
    final venue = json['venue'];
    final country = json['country'];
    final postcode = json['postcode'];
    final address = json['address'];
    final latitude = (json['latitude'] as num).toDouble();
    final longitude = (json['longitude'] as num).toDouble();
    final bannerUrl = json['bannerUrl'];
    final status = json['status'];
    final genre = json['genre'].cast<String>();
    final hostName = json['hostName'];
    final lineup = json['lineup']?.cast<String>();
    final timeline = json['timeline']?.cast<String>();
    final ticketPrice = (json['ticketPrice'] as num).toInt();
    final ticketsUrl = json['ticketsUrl'];
    return Event(id, name, category, description, startDateTime, endDateTime, city, venue, country, postcode, address, latitude, longitude, bannerUrl, status, genre, hostName, lineup, timeline,
        ticketPrice, ticketsUrl);
  }
}
