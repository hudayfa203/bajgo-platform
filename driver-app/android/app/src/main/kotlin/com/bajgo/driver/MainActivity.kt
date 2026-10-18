package com.bajgo.driver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * Notification channels must exist before flutter_background_service starts the
     * foreground location service. Created natively so no extra plugin is needed.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val location = NotificationChannel(
            LOCATION_CHANNEL_ID,
            "BajGo location",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while you are online so BajGo can send your position to riders."
            setShowBadge(false)
        }
        manager.createNotificationChannel(location)

        val offers = NotificationChannel(
            OFFERS_CHANNEL_ID,
            "BajGo requests",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New ride and delivery requests."
        }
        manager.createNotificationChannel(offers)
    }

    companion object {
        const val LOCATION_CHANNEL_ID = "bajgo_location"
        const val OFFERS_CHANNEL_ID = "bajgo_offers"
    }
}
