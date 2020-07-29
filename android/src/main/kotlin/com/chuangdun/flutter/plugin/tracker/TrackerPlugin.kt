package com.chuangdun.flutter.plugin.tracker

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

const val METHOD_CHANNEL_NAME = "com.chuangdun.flutter/tracker/methods"
const val EVENT_CHANNEL_NAME = "com.chuangdun.flutter/tracker/events"
const val REQUEST_PERMISSION = 10001

/** TrackerPlugin */
public class TrackerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var methodChannel: MethodChannel

    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    companion object {
      private const val TAG = "TrackerPlugin"
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val trackerPlugin = TrackerPlugin()
            trackerPlugin.context = registrar.context()
            trackerPlugin.activity = registrar.activity()
            registrar.addRequestPermissionsResultListener(trackerPlugin)
            val channel = MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME)
            channel.setMethodCallHandler(trackerPlugin)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (activity == null || context == null) {
            result.success(false)
            return
        }
        when (call.method) {
            "start" -> {
                val permissions = mutableListOf(Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_FINE_LOCATION)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                }
                val notGrantedPermissions = permissions.filterNot {
                    ActivityCompat.checkSelfPermission(context!!, it) == PackageManager.PERMISSION_GRANTED
                }
                if (notGrantedPermissions.isNotEmpty()) {
                    ActivityCompat.requestPermissions(activity!!, notGrantedPermissions.toTypedArray(), REQUEST_PERMISSION)
                }
                val postUrl = call.argument<String>("postUrl")
                val headers = call.argument<Map<String, String>>("headers")
                val extraBody = call.argument<Map<String, String>>("extraBody")
                val minTimeInterval = call.argument<Int>("minTimeInterval")
                val minDistance = call.argument<Double>("minDistance")
                val notificationTitle = call.argument<String>("notificationTitle")
                val notificationContent = call.argument<String>("notificationContent")
                if (postUrl == null || headers == null || extraBody == null || minTimeInterval == null
                        || minDistance == null || notificationTitle == null || notificationContent == null) {
                    throw IllegalArgumentException("定位参数有误,请检查.")
                }
                TrackerManager.start(context!!, postUrl, headers, extraBody, minTimeInterval,
                        minDistance.toFloat(), notificationTitle, notificationContent)
                result.success(true)
            }
            "stop" -> {
                TrackerManager.shutdown(context!!)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        if (REQUEST_PERMISSION == requestCode) {
            var granted = if (grantResults != null) {
                var temporary = true
                for (grantResult in grantResults) {
                    temporary = temporary && grantResult == PackageManager.PERMISSION_DENIED
                }
                temporary
            } else {
                false
            }
          Log.d(TAG, "用户是否已授权:$granted")
        }
        return true
    }
}
