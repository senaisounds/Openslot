package com.openslot.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.openslot/deep_links"
    private var initialLink: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if the activity was started from a deep link
        if (intent?.action == Intent.ACTION_VIEW) {
            initialLink = intent.data?.toString()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Set up method channel for deep link handling
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(initialLink)
                    // Clear after it's been delivered
                    initialLink = null
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Handle deep links when app is running
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        if (intent.action == Intent.ACTION_VIEW) {
            val deepLink = intent.data?.toString()
            if (deepLink != null) {
                methodChannel?.invokeMethod("handleDeepLink", deepLink)
            }
        }
    }
} 