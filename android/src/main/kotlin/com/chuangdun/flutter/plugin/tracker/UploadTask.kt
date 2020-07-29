package com.chuangdun.flutter.plugin.tracker

import android.util.Log
import okhttp3.Headers
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class UploadTask(
        private val status: Status,
        private val postUrl: String,
        private val latitude: Double,
        private val longitude: Double,
        private val timestamp: Long,
        private val platform: String = "android",
        private val deviceBrand: String,
        private val deviceModel: String,
        private val systemVersion: Int,
        private val headers: JSONObject,
        private val extraBody: JSONObject) : Runnable {

    companion object {
        private const val TAG = "UploadTask"
    }

    override fun run() {
        try {
            val httpClient = OkHttpClient.Builder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(15, TimeUnit.SECONDS)
                    .writeTimeout(10, TimeUnit.SECONDS)
                    .build()
            extraBody.apply {
                put("status", status.name)
                put("platform", platform)
                put("latitude", latitude)
                put("longitude", longitude)
                put("timestamp", timestamp)
                put("deviceBrand", deviceBrand)
                put("deviceModel", deviceModel)
                put("systemVersion", systemVersion)
            }
            val requestBody = extraBody.toString(4)
                    .toRequestBody("application/json; charset=utf-8".toMediaType())
            val okHttpHeaderBuilder = Headers.Builder()
            headers.keys().forEach { okHttpHeaderBuilder.add(it, headers.getString(it)) }
            val request = Request.Builder()
                    .url(postUrl)
                    .headers(okHttpHeaderBuilder.build())
                    .post(requestBody)
                    .build()
            val response = httpClient.newCall(request).execute()
            if (response.code == 200) {
                val json = JSONObject(response.body!!.string())
                Log.d(TAG, "响应：${json.toString(4)}")
                val code = json.getInt("code")
                if (200 == code) {
                    Log.d(TAG, "位置上报成功.")
                } else {
                    throw Exception("位置上报失败, 响应码: $code")
                }
            } else {
                throw Exception("位置上报请求失败, 响应码: ${response.code}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "位置上报失败", e)
        }
    }

    enum class Status {
        LOCATION,
        PERMISSION_DENIED,
        NOT_AVAILABLE;
    }
}