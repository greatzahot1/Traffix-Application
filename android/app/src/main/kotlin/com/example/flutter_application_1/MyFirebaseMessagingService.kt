package com.example.flutter_application_1

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // Handle incoming messages and notifications
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)

        // Save or update the token on your server
    }
}