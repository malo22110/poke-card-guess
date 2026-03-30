import 'package:uuid/uuid.dart';

class UserProfile {
  final String? id; // Backend ID for auth users, null or generated for guests?
  final String name;
  final String? picture;
  final String? authToken;
  final bool isGuest;

  UserProfile({
    this.id,
    required this.name,
    this.picture,
    this.authToken,
    this.isGuest = false,
  });

  factory UserProfile.guest(String name, String? avatar, {String? overrideId}) {
    return UserProfile(
      id: overrideId ?? "guest-${const Uuid().v4()}",
      name: name,
      picture: avatar,
      isGuest: true,
    );
  }

  factory UserProfile.authenticated({
    required String id,
    required String name,
    required String authToken,
    String? picture,
  }) {
    return UserProfile(
      id: id,
      name: name,
      authToken: authToken,
      picture: picture,
      isGuest: false,
    );
  }
}
