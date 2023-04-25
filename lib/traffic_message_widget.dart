import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'traffic_message.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrafficMessageWidget extends StatefulWidget {
  final TrafficMessage trafficMessage;
  final Function(bool) onLike;
  final Function(bool) onDislike;
  final VoidCallback onComment;
  final String? userId;
  final List<String>? likedBy;
  final List<String>? dislikedBy;
  final String? displayName;
  final String? photoURL;

  TrafficMessageWidget({
    required this.trafficMessage,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.userId,
    required this.likedBy,
    required this.dislikedBy,
    this.displayName,
    this.photoURL,
  });

  @override
  _TrafficMessageWidgetState createState() => _TrafficMessageWidgetState();
}

class _TrafficMessageWidgetState extends State<TrafficMessageWidget> {
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      isLiked = widget.trafficMessage.likedBy?.contains(widget.userId) ?? false;
      isDisliked =
          widget.trafficMessage.dislikedBy?.contains(widget.userId) ?? false;
    }
  }

  void _toggleLike() {
    setState(() {
      if (isDisliked) {
        isDisliked = false;
        widget.onDislike(false);
      }
      isLiked = !isLiked;
      widget.onLike(isLiked);
    });
  }

  void _toggleDislike() {
    setState(() {
      if (isLiked) {
        isLiked = false;
        widget.onLike(false);
      }
      isDisliked = !isDisliked;
      widget.onDislike(isDisliked);
    });
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Comments'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.trafficMessage.comments?.length ?? 0,
              itemBuilder: (context, index) {
                final comment = widget.trafficMessage.comments![index];
                return ListTile(
                  leading: Icon(Icons.comment),
                  title: Text(comment['comment'] ?? 'Unknown comment'),
                  subtitle: Text('User: ${comment['userId']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.photoURL != null
                  ? NetworkImage(widget.photoURL!)
                  : NetworkImage('https://via.placeholder.com/150'),
              radius: 30,
            ),
            title: Text(widget.displayName ?? 'Unknown user'),
            subtitle: Text(widget.trafficMessage.message ?? 'Unknown message'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up, color: isLiked ? Colors.blue : null),
                onPressed: _toggleLike,
              ),
              Text('${widget.trafficMessage.likes ?? 0} Likes'),
              IconButton(
                icon: Icon(Icons.thumb_down,
                    color: isDisliked ? Colors.blue : null),
                onPressed: _toggleDislike,
              ),
              Text('${widget.trafficMessage.dislikes ?? 0} Dislikes'),
              IconButton(
                icon: Icon(Icons.comment),
                onPressed: () {
                  _showCommentDialog();
                  widget.onComment();
                },
              ),
              Text('${widget.trafficMessage.comments?.length ?? 0} Comments'),
            ],
          ),
        ],
      ),
    );
  }
}
