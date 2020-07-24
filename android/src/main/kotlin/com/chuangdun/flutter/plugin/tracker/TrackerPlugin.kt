package com.chuangdun.flutter.plugin.tracker

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

const val METHOD_CHANNEL_NAME = "com.chuangdun.flutter/tracker/methods"
const val EVENT_CHANNEL_NAME = "com.chuangdun.flutter/tracker/events"


/** TrackerPlugin */
public class TrackerPlugin: FlutterPlugin, MethodCallHandler{
  private lateinit var methodChannel : MethodChannel
  private lateinit var context: Context
  private lateinit var activity: Activity

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), METHOD_CHANNEL_NAME)
    methodChannel.setMethodCallHandler(this)
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val trackerPlugin = TrackerPlugin()
      trackerPlugin.context = registrar.context()

      val channel = MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME)
      channel.setMethodCallHandler(trackerPlugin)
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when(call.method){
      "start" -> {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q){
          arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION,
                  Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }else{
          arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        val notGrantedPermissions = permissions.filterNot {
          ActivityCompat.checkSelfPermission(context,it) == PackageManager.PERMISSION_GRANTED}
        if (notGrantedPermissions.isNotEmpty()){
          ActivityCompat.requestPermissions(activity, notGrantedPermissions.toTypedArray(), 9999)
        }
      }
      "stop" -> {

      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
  }

}
