// frontend/lib/services/user_session.dart
// Simple singleton to hold the logged-in user's info.
// Call UserSession().set(...) right after your login API succeeds.

class UserSession {
  static final UserSession _i = UserSession._();
  factory UserSession() => _i;
  UserSession._();

  String userId = '';
  String username = '';
  String name = '';
  String initials = '';

  void set({
    required String userId,
    required String username,
    required String name,
  }) {
    this.userId = userId;
    this.username = username;
    this.name = name;
    final parts = name.trim().split(' ');
    initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';
  }

  void clear() {
    userId = '';
    username = '';
    name = '';
    initials = '';
  }

  bool get isLoggedIn => userId.isNotEmpty;
}
