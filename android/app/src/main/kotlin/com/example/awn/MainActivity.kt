package com.example.awn

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Define the sound URI
            val soundUri = Uri.parse("android.resource://" + packageName + "/raw/custom_sound")

            // Set up audio attributes
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            // Create the notification channel
            val channel = NotificationChannel(
                "channel_id", // Unique ID for this channel
                "Custom Notifications", // Channel name
                NotificationManager.IMPORTANCE_HIGH // Importance level
            )
            channel.setSound(soundUri, audioAttributes)

            // Register the channel with the system
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
