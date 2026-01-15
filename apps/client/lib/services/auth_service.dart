
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pokecardguess/config/app_config.dart';
import 'package:pokecardguess/models/user_profile.dart';
import 'auth_storage_service.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser != null && _currentUser!.isGuest;

  final AuthStorageService _storage = AuthStorageService();

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token != null) {
        // Validate token and fetch profile
        final success = await _fetchUserProfile(token);
        if (!success) {
           await _storage.clearSession();
        }
      } else {
        // Check for guest session
        final guestName = await _storage.getGuestName();
        // guestAvatar? storage doesn't seem to have it, but maybe we should add it or ignore for now.
        // Assuming guestAvatar is not persisted or we need to add it to storage. 
        // For now, if guestName exists, restore guest session.
        if (guestName != null) {
           _currentUser = UserProfile.guest(guestName, null);
        }
      }
    } catch (e) {
      print('Error loading session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.authenticated(
          id: data['id'],
          name: data['name'],
          authToken: token,
          picture: data['picture'],
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return false;
    }
  }

  Future<void> login(String token) async {
    await _storage.saveSession(token: token);
    await _fetchUserProfile(token);
    notifyListeners();
  }

  Future<void> loginAsGuest(String name, String? avatar) async {
    await _storage.saveGuestName(name);
    _currentUser = UserProfile.guest(name, avatar);
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
