import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/settings_data.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'logger.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      Logger.log('User signed out');
    } catch (e) {
      Logger.logError('Error signing out: $e');
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
        Logger.log('Display name updated: $newName');
      }
    } catch (e) {
      Logger.logError('Error updating display name: $e');
    }
  }

  void _showEditDisplayNameDialog(BuildContext context) async {
    TextEditingController _nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Display Name'),
          content: TextField(
            controller: _nameController,
            decoration:
                InputDecoration(hintText: 'Enter your new display name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await _updateDisplayName(_nameController.text);
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfilePicture(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Upload the image to Firebase Storage and update the user's photo URL
        File file = File(pickedFile.path);

        // Create a reference to the Firebase Storage location
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${Path.basename(pickedFile.path)}');

        // Upload the image to Firebase Storage
        UploadTask uploadTask = storageRef.putFile(file);

        // Wait for the upload to complete and get the download URL
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Update the user's photo URL
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(downloadUrl);
          await user.reload();
          setState(() {}); // Refresh the UI to show the updated photo
        }
        Logger.log('Profile picture updated');
      }
    } catch (e) {
      Logger.logError('Error updating profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Consumer<SettingsData>(
      builder: (context, settingsData, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Settings'),
          ),
          body: ListView(
            children: [
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : NetworkImage('https://via.placeholder.com/150'),
                        radius: 30,
                      ),
                      title: Text(user?.displayName ?? 'User'),
                      subtitle: Text(user?.email ?? 'Email'),
                    ),
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Name'),
                      onTap: () => _showEditDisplayNameDialog(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.image),
                      title: Text('Change Profile Picture'),
                      onTap: () => _updateProfilePicture(context),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Traffic Data'),
                      value: settingsData.trafficEnabled,
                      onChanged: (bool value) {
                        settingsData.setTrafficEnabled(value);
                      },
                    ),
                    ListTile(
                      title: Text('Map Type'),
                      trailing: DropdownButton<MapType>(
                        value: settingsData.mapType,
                        items: [
                          DropdownMenuItem<MapType>(
                            value: MapType.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem<MapType>(
                            value: MapType.satellite,
                            child: Text('Satellite'),
                          ),
                          DropdownMenuItem<MapType>(
                            value: MapType.terrain,
                            child: Text('Terrain'),
                          ),
                        ],
                        onChanged: (MapType? newValue) {
                          if (newValue != null) {
                            settingsData.setMapType(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                  onTap: () => _signOut(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
