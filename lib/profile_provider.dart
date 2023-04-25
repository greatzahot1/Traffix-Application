import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile.dart';

class ProfileProvider with ChangeNotifier {
  final String uid;

  ProfileProvider({required this.uid});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Profile> fetchProfile() async {
    DocumentSnapshot doc =
        await _firestore.collection('user_profiles').doc(uid).get();
    return Profile.fromSnapshot(doc);
  }

  Future<void> updateProfile(Profile profile) async {
    await _firestore.collection('user_profiles').doc(uid).set(profile.toMap());
    notifyListeners();
  }
}
