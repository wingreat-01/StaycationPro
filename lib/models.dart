import 'package:intl/intl.dart';

final peso = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
final shortDate = DateFormat('MMM d, yyyy');

String toDateString(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  bool get isOwner => role == 'owner';

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'] as String,
    fullName: m['full_name'] as String? ?? '',
    phone: m['phone'] as String?,
    role: m['role'] as String? ?? 'guest',
  );
}

class Listing {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String location;
  final double pricePerNight;
  final int maxGuests;
  final String? imageUrl;
  final bool isActive;

  const Listing({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.pricePerNight,
    required this.maxGuests,
    this.imageUrl,
    this.isActive = true,
  });

  factory Listing.fromMap(Map<String, dynamic> m) => Listing(
    id: m['id'] as String,
    ownerId: m['owner_id'] as String,
    title: m['title'] as String,
    description: m['description'] as String? ?? '',
    location: m['location'] as String,
    pricePerNight: (m['price_per_night'] as num).toDouble(),
    maxGuests: m['max_guests'] as int,
    imageUrl: m['image_url'] as String?,
    isActive: m['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toMap() => {
    'owner_id': ownerId,
    'title': title,
    'description': description,
    'location': location,
    'price_per_night': pricePerNight,
    'max_guests': maxGuests,
    'image_url': imageUrl,
    'is_active': isActive,
  };
}

enum BookingStatus { pending, accepted, declined, cancelled }

class Booking {
  final String id;
  final String listingId;
  final String guestId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final BookingStatus status;
  final String? note;
  final DateTime createdAt;

  // Joined fields; null when the related row isn't visible to this user.
  final String? listingTitle;
  final String? listingLocation;
  final String? guestName;
  final String? guestPhone;

  const Booking({
    required this.id,
    required this.listingId,
    required this.guestId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.note,
    required this.createdAt,
    this.listingTitle,
    this.listingLocation,
    this.guestName,
    this.guestPhone,
  });

  int get nights => checkOut.difference(checkIn).inDays;

  bool get isUpcoming => !checkOut.isBefore(DateTime.now());

  /// Whether the guest stays the night of [day]. The check-out day itself
  /// is free for the next guest.
  bool coversNight(DateTime day) =>
      !day.isBefore(checkIn) && day.isBefore(checkOut);

  factory Booking.fromMap(Map<String, dynamic> m) {
    final listing = m['listings'] as Map<String, dynamic>?;
    final guest = m['guest'] as Map<String, dynamic>?;
    return Booking(
      id: m['id'] as String,
      listingId: m['listing_id'] as String,
      guestId: m['guest_id'] as String,
      checkIn: DateTime.parse(m['check_in'] as String),
      checkOut: DateTime.parse(m['check_out'] as String),
      guests: m['guests'] as int,
      totalPrice: (m['total_price'] as num).toDouble(),
      status: BookingStatus.values.byName(m['status'] as String),
      note: m['note'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      listingTitle: listing?['title'] as String?,
      listingLocation: listing?['location'] as String?,
      guestName: guest?['full_name'] as String?,
      guestPhone: guest?['phone'] as String?,
    );
  }
}

class DateSpan {
  final DateTime start;
  final DateTime end; // exclusive (check-out day)

  const DateSpan(this.start, this.end);

  bool overlaps(DateTime otherStart, DateTime otherEnd) =>
      start.isBefore(otherEnd) && otherStart.isBefore(end);
}
