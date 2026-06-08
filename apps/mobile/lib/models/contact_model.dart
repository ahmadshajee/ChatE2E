// ============================================================
//  Contact Model
//  Represents a user found via search.
// ============================================================

class ContactModel {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? identityPublicKey;

  ContactModel({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.identityPublicKey,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'User',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      identityPublicKey: json['identity_public_key'] as String?,
    );
  }

  /// Get initials for avatar.
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
