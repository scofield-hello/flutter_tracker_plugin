package com.chuangdun.flutter.plugin.tracker

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class ServiceLauncher(private val context: Context, private val workerParams: WorkerParameters) : Worker(context, workerParams) {

    companion object {
        private const val TAG = "ServiceLauncher"
    }

    override fun doWork(): Result {
        Log.i(TAG, "doWork")
        val params = workerParams.inputData.keyValueMap
        val postUrl = params["postUrl"] as String
        val headers = params["headers"] as String
        val extraBody = params["extraBody"] as String
        val minTimeInterval = params["minTimeInterval"] as Int
        val minDistance = params["minDistance"] as Float
        val notificationChannelId = params["notificationChannelId"] as String
        val notificationChannelName = params["notificationChannelName"] as String
        val notificationChannelDescription = params["notificationChannelDescription"] as String
        val notificationTitle = params["notificationTitle"] as String
        val notificationContent = params["notificationContent"] as String
        val intent = Intent(context, TrackerService::class.java)
        intent.putExtra("command", TrackerCommand.ON)
        intent.putExtra("postUrl", postUrl)
        intent.putExtra("headers", headers)
        intent.putExtra("extraBody", extraBody)
        intent.putExtra("minTimeInterval", minTimeInterval)
        intent.putExtra("minDistance", minDistance)
        intent.putExtra("notificationChannelId", notificationChannelId)
        intent.putExtra("notificationChannelName", notificationChannelName)
        intent.putExtra("notificationChannelDescription", notificationChannelDescription)
        intent.putExtra("notificationTitle", notificationTitle)
        intent.putExtra("notificationContent", notificationContent)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            context.startService(intent)
        } else {
            context.startForegroundService(intent)
        }
        return Result.success()
    }

    override fun onStopped() {
        super.onStopped()
        val intent = Intent(context, TrackerService::class.java)
        intent.putExtra("command", TrackerCommand.OFF)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            context.startService(intent)
        } else {
            context.startForegroundService(intent)
        }
        Log.d(TAG, "stopped")
    }

}