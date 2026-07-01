import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/football_field.dart';
import '../models/booking.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Football Fields
  Future<List<FootballField>> getFootballFields() async {
    final response = await _client.from('football_fields').select();
    return (response as List).map((json) => FootballField.fromJson(json)).toList();
  }

  Future<FootballField> getFootballField(String id) async {
    final response = await _client.from('football_fields').select().eq('id', id).single();
    return FootballField.fromJson(response);
  }

  // Bookings
  Future<List<Booking>> getMyBookings() async {
    final response = await _client
        .from('bookings')
        .select('*, football_fields(name, address)')
        .eq('user_id', currentUser!.id)
        .order('booking_date', ascending: false);
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await _client.from('bookings').insert(booking.toJson()).select('*, football_fields(name, address)').single();
    return Booking.fromJson(response);
  }

  Future<void> cancelBooking(String id) async {
    await _client.from('bookings').update({'status': 'cancelled'}).eq('id', id);
  }

  // Check available time slots
  Future<List<Map<String, dynamic>>> getBookedSlots(String fieldId, DateTime date) async {
    final response = await _client
        .from('bookings')
        .select('start_time, end_time')
        .eq('field_id', fieldId)
        .eq('booking_date', date.toIso8601String().split('T')[0])
        .neq('status', 'cancelled');
    return (response as List).cast<Map<String, dynamic>>();
  }
}
