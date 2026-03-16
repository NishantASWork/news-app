class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });
}
