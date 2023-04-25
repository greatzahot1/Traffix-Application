import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'traffic_message.dart';
import 'traffic_message_widget.dart';
import 'logger.dart';

class TrafficAlertsPage extends StatefulWidget {
  @override
  _TrafficAlertsPageState createState() => _TrafficAlertsPageState();
}

class _TrafficAlertsPageState extends State<TrafficAlertsPage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Stream<QuerySnapshot> _getTrafficMessagesStream() {
    return FirebaseFirestore.instance
        .collection('traffic_messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _updateTrafficMessageField(TrafficMessage trafficMessage,
      String field, int increment, bool add) async {
    try {
      await FirebaseFirestore.instance
          .collection('traffic_messages')
          .doc(trafficMessage.id)
          .update({
        field: FieldValue.increment(increment),
        '${add ? 'likedBy' : 'dislikedBy'}': add
            ? FieldValue.arrayUnion([user!.uid])
            : FieldValue.arrayRemove([user!.uid]),
      });
      Logger.log('Traffic message field updated',
          data: trafficMessage.id, tag: 'Update');
    } catch (e) {
      Logger.logError(e, tag: 'Update');
    }
  }

  Future<void> _addComment(
      TrafficMessage trafficMessage, String comment) async {
    try {
      await FirebaseFirestore.instance
          .collection('traffic_messages')
          .doc(trafficMessage.id)
          .update({
        'comments': FieldValue.arrayUnion([
          {
            'userId': user?.uid,
            'comment': comment,
            'timestamp': DateTime.now(),
          }
        ]),
      });
      Logger.log('Comment added', data: trafficMessage.id, tag: 'Comment');
    } catch (e) {
      Logger.logError(e, tag: 'Comment');
    }
  }

  void _showCommentDialog(TrafficMessage trafficMessage) async {
    TextEditingController _commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Comment'),
          content: TextField(
            controller: _commentController,
            decoration: InputDecoration(hintText: 'Enter your comment'),
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
                if (_commentController.text.isNotEmpty) {
                  await _addComment(trafficMessage, _commentController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traffic Alerts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTrafficMessagesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final trafficMessage =
                  TrafficMessage.fromSnapshot(messages[index]);

              return TrafficMessageWidget(
                trafficMessage: TrafficMessage.fromSnapshot(messages[index]),
                userId: user?.uid,
                likedBy: trafficMessage.likedBy,
                dislikedBy: trafficMessage.dislikedBy,
                displayName: trafficMessage.displayName, // ส่งค่า displayName
                photoURL: trafficMessage.photoURL, // ส่งค่า photoURL
                onLike: (isLiked) {
                  _updateTrafficMessageField(
                      trafficMessage, 'likes', isLiked ? 1 : -1, isLiked);
                },
                onDislike: (isDisliked) {
                  _updateTrafficMessageField(trafficMessage, 'dislikes',
                      isDisliked ? 1 : -1, isDisliked);
                },
                onComment: () {
                  _showCommentDialog(trafficMessage);
                },
              );
            },
          );
        },
      ),
    );
  }
}
