import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

SupabaseClient get supabase => Supabase.instance.client;

String get currentUserId => supabase.auth.currentUser!.id;

const _bookingSelect =
    '*, listings!inner(title, location, owner_id), guest:profiles(full_name, phone)';

/// Turns Supabase errors into a message fit to show the user.
String errorMessage(Object e) {
  if (e is PostgrestException) return e.message;
  if (e is AuthException) return e.message;
  return 'Something went wrong. Please try again.';
}

Future<Profile> fetchProfile() async {
  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', currentUserId)
      .single();
  return Profile.fromMap(row);
}

Future<void> updateProfile({required String fullName, String? phone}) async {
  await supabase
      .from('profiles')
      .update({'full_name': fullName, 'phone': phone})
      .eq('id', currentUserId);
}

// --- Listings ---------------------------------------------------------------

Future<List<Listing>> fetchActiveListings({String search = ''}) async {
  var query = supabase.from('listings').select().eq('is_active', true);
  // Commas and parentheses would break PostgREST's `or` filter syntax.
  final term = search.replaceAll(RegExp(r'[,()]'), ' ').trim();
  if (term.isNotEmpty) {
    final q = '%$term%';
    query = query.or('title.ilike.$q,location.ilike.$q');
  }
  final rows = await query.order('created_at', ascending: false);
  return rows.map(Listing.fromMap).toList();
}

Future<List<Listing>> fetchMyListings() async {
  final rows = await supabase
      .from('listings')
      .select()
      .eq('owner_id', currentUserId)
      .order('created_at', ascending: false);
  return rows.map(Listing.fromMap).toList();
}

Future<void> saveListing(Listing listing) async {
  if (listing.id == null) {
    await supabase.from('listings').insert(listing.toMap());
  } else {
    await supabase
        .from('listings')
        .update(listing.toMap())
        .eq('id', listing.id!);
  }
}

const _photoBucket = 'listing-photos';

/// Uploads a listing photo to Supabase Storage and returns its public URL.
/// Files go in a folder named after the user, which the storage policies
/// require.
Future<String> uploadListingPhoto(Uint8List bytes, String extension) async {
  final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
  final path = '$currentUserId/${DateTime.now().millisecondsSinceEpoch}.$ext';
  await supabase.storage
      .from(_photoBucket)
      .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext',
        ),
      );
  return supabase.storage.from(_photoBucket).getPublicUrl(path);
}

/// Removes a previously uploaded photo. Ignores URLs that aren't ours
/// (e.g. older listings that used a pasted link).
Future<void> deleteListingPhoto(String url) async {
  final marker = '/$_photoBucket/';
  final i = url.indexOf(marker);
  if (i == -1) return;
  final path = url.substring(i + marker.length);
  if (!path.startsWith('$currentUserId/')) return;
  await supabase.storage.from(_photoBucket).remove([path]);
}

Future<void> deleteListing(String id) async {
  await supabase.from('listings').delete().eq('id', id);
}

Future<List<DateSpan>> fetchBookedRanges(String listingId) async {
  final rows = await supabase.rpc(
    'listing_booked_ranges',
    params: {'p_listing_id': listingId},
  );
  return (rows as List)
      .map(
        (r) => DateSpan(
          DateTime.parse(r['check_in'] as String),
          DateTime.parse(r['check_out'] as String),
        ),
      )
      .toList();
}

// --- Bookings ---------------------------------------------------------------

Future<void> requestBooking({
  required String listingId,
  required DateTime checkIn,
  required DateTime checkOut,
  required int guests,
  String? note,
}) async {
  await supabase.from('bookings').insert({
    'listing_id': listingId,
    'guest_id': currentUserId,
    'check_in': toDateString(checkIn),
    'check_out': toDateString(checkOut),
    'guests': guests,
    'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
  });
}

Future<List<Booking>> fetchGuestBookings() async {
  final rows = await supabase
      .from('bookings')
      .select(_bookingSelect)
      .eq('guest_id', currentUserId)
      .order('check_in', ascending: false);
  return rows.map(Booking.fromMap).toList();
}

Future<List<Booking>> fetchOwnerBookings() async {
  final rows = await supabase
      .from('bookings')
      .select(_bookingSelect)
      .eq('listings.owner_id', currentUserId)
      .order('check_in');
  return rows.map(Booking.fromMap).toList();
}

Future<void> respondToBooking(String bookingId, {required bool accept}) async {
  await supabase.rpc(
    'respond_to_booking',
    params: {'p_booking_id': bookingId, 'p_accept': accept},
  );
}

Future<void> cancelBooking(String bookingId) async {
  await supabase.rpc('cancel_booking', params: {'p_booking_id': bookingId});
}
