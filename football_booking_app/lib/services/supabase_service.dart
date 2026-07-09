import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/football_field.dart';
import '../models/booking.dart';
import '../models/user_profile.dart';
import '../models/time_slot.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, {String fullName = '', String phone = ''}) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
      });
    }
    return response;
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

  // User Profile
  Future<UserProfile> getProfile() async {
    final response = await _client.from('profiles').select().eq('id', currentUser!.id).single();
    return UserProfile.fromJson(response);
  }

  Future<void> updateProfileRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }

  Future<void> createAdminUser(String email, String password, String fullName, String phone) async {
    final url = Uri.parse('${AppConstants.supabaseUrl}/auth/v1/signup');
    final response = await http.post(
      url,
      headers: {
        'apikey': AppConstants.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'full_name': fullName,
          'phone': phone,
        }
      }),
    );
    
    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['msg'] ?? 'Failed to create user');
    }
    
    final jsonResponse = jsonDecode(response.body);
    final userId = jsonResponse['user'] != null ? jsonResponse['user']['id'] : jsonResponse['id'];
    
    if (userId == null) {
      throw Exception('Failed to create user');
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'role': 'admin',
    });
  }


  Future<List<UserProfile>> getAllProfiles() async {
    final response = await _client.from('profiles').select();
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }

  // Admin: Football Fields
  Future<void> addFootballField(Map<String, dynamic> field) async {
    await _client.from('football_fields').insert(field);
  }

  Future<void> updateFootballField(String id, Map<String, dynamic> field) async {
    await _client.from('football_fields').update(field).eq('id', id);
  }

  Future<void> deleteFootballField(String id) async {
    await _client.from('football_fields').delete().eq('id', id);
  }

  // Admin: All Bookings
  Future<List<Booking>> getAllBookings() async {
    final response = await _client
        .from('bookings')
        .select('*, football_fields(name, address)')
        .order('booking_date', ascending: false);
        
    final bookingsList = (response as List).cast<Map<String, dynamic>>();
    
    final userIds = bookingsList.map((b) => b['user_id'] as String).toSet().toList();
    if (userIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name, phone')
          .inFilter('id', userIds);
          
      final profilesList = (profilesResponse as List).cast<Map<String, dynamic>>();
      final profileMap = {for (var p in profilesList) p['id'] as String: p};
      
      for (var booking in bookingsList) {
        final profile = profileMap[booking['user_id']];
        if (profile != null) {
          booking['profiles'] = {
            'full_name': profile['full_name'],
            'phone': profile['phone'],
          };
        }
      }
    }
    
    return bookingsList.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _client.from('bookings').update({'status': status}).eq('id', id);
  }

  // Admin: Time Slots
  Future<List<TimeSlot>> getTimeSlots(String fieldId) async {
    final response = await _client
        .from('time_slots')
        .select()
        .eq('field_id', fieldId)
        .order('start_time');
    return (response as List).map((json) => TimeSlot.fromJson(json)).toList();
  }

  Future<void> addTimeSlot(TimeSlot slot) async {
    await _client.from('time_slots').insert(slot.toJson());
  }

  Future<void> updateTimeSlot(String id, Map<String, dynamic> data) async {
    await _client.from('time_slots').update(data).eq('id', id);
  }

  Future<void> deleteTimeSlot(String id) async {
    await _client.from('time_slots').delete().eq('id', id);
  }

  Future<void> toggleTimeSlotAvailability(String id, bool isAvailable) async {
    await _client.from('time_slots').update({'is_available': isAvailable}).eq('id', id);
  }

  // Check available time slots
  Future<List<TimeSlot>> getAvailableTimeSlots(String fieldId) async {
    final response = await _client
        .from('time_slots')
        .select()
        .eq('field_id', fieldId)
        .eq('is_available', true)
        .order('start_time');
    return (response as List).map((json) => TimeSlot.fromJson(json)).toList();
  }

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
