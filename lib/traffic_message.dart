import 'package:cloud_firestore/cloud_firestore.dart';

class TrafficMessage {
  final String? id;
  final String? userId;
  final String? message;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;
  int? likes;
  int? dislikes;
  List<String>? likedBy;
  List<String>? dislikedBy;
  List<Map<String, dynamic>>? comments;
  final String? displayName;
  final String? photoURL;

  TrafficMessage({
    this.id,
    this.userId,
    this.message,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.likes,
    this.dislikes,
    this.likedBy,
    this.dislikedBy,
    this.comments,
    this.displayName,
    this.photoURL,
  });

  factory TrafficMessage.fromMap(Map<String, dynamic> data, String documentId) {
    return TrafficMessage(
      id: documentId,
      userId: data['userId'],
      message: data['message'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'],
      dislikes: data['dislikes'],
      likedBy: (data['likedBy'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      dislikedBy: (data['dislikedBy'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((dynamic e) => e as Map<String, dynamic>)
          .toList(),
      displayName: data['displayName'],
      photoURL: data['photoURL'],
    );
  }

  factory TrafficMessage.fromSnapshot(DocumentSnapshot snapshot) {
    return TrafficMessage.fromMap(
        snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'likes': likes,
      'dislikes': dislikes,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'comments': comments,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
