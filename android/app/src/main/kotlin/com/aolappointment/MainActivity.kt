package com.aolappointment.v2

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Allow screenshots (remove FLAG_SECURE if it exists)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
