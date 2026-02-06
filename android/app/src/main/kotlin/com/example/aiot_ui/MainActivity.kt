package com.example.aiot_ui

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle // <-- Required for onCreate
import android.view.WindowManager // <-- Required for FLAG_SECURE
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {

    // Running this code in onCreate is the earliest and most robust point
    // to manipulate the window flags, overriding persistent secure settings.
    override fun onCreate(savedInstanceState: Bundle?) {
        // Must call super.onCreate first to establish the window context
        super.onCreate(savedInstanceState)

        // =======================================================
        // FINAL FIX: Explicitly clear the FLAG_SECURE flag immediately.
        // This should override ANY plugin or theme setting that enforces
        // the screenshot restriction.
        // =======================================================
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    // Keeping configureFlutterEngine for necessary Flutter setup (like plugins)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
}
