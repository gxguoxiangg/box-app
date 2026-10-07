package com.example.demo1

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** 按用户操作申请 Wi-Fi BSSID 所需的 Android 精确位置权限。 */
class MainActivity : FlutterActivity() {
    private val wifiPermissionRequestCode = 7342
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "busybox/wifi_access")
            .setMethodCallHandler { call, result ->
                if (call.method != "requestLocationPermission") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED) {
                    result.success(true)
                } else if (pendingResult != null) {
                    result.error("in_progress", "位置权限请求正在进行", null)
                } else {
                    pendingResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                        wifiPermissionRequestCode
                    )
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == wifiPermissionRequestCode) {
            pendingResult?.success(grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED)
            pendingResult = null
        }
    }
}
