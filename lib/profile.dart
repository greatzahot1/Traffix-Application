import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String? id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  var name;

  Profile({
    this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> data, String documentId) {
    return Profile(
      id: documentId,
      displayName: data['displayName'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Profile.fromSnapshot(DocumentSnapshot snapshot) {
    return Profile.fromMap(
        snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
