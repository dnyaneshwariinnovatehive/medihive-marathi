package com.innovatehive.medihive

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val SHARE_CHANNEL = "com.innovatehive.medihive/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARG", "filePath is required", null)
                    return@setMethodCallHandler
                }

                var phoneNumber = call.argument<String>("phoneNumber")?.replace(Regex("[^0-9]"), "") ?: ""

                // Prepend India country code if it's a 10-digit number
                if (phoneNumber.length == 10) {
                    phoneNumber = "91$phoneNumber"
                }

                try {
                    val file = File(filePath)
                    val uri: Uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        file
                    )

                    // Save a copy to public Downloads folder for easy manual access
                    saveToDownloads(file)

                    val whatsappPkgs = listOf("com.whatsapp", "com.whatsapp.w4b")
                    var launched = false

                    // Step 1: Open specific chat directly via wa.me deep link (WhatsApp's official format)
                    if (phoneNumber.isNotEmpty()) {
                        for (pkg in whatsappPkgs) {
                            try {
                                packageManager.getPackageInfo(pkg, 0)
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$phoneNumber"))
                                intent.setPackage(pkg)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                launched = true
                                break
                            } catch (_: Exception) { }
                        }
                    }

                    // Step 2: Fallback to api.whatsapp.com deep link if wa.me fails
                    if (!launched && phoneNumber.isNotEmpty()) {
                        for (pkg in whatsappPkgs) {
                            try {
                                packageManager.getPackageInfo(pkg, 0)
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber"))
                                intent.setPackage(pkg)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                launched = true
                                break
                            } catch (_: Exception) { }
                        }
                    }

                    // Final fallback: system share sheet
                    if (!launched) {
                        startActivity(Intent.createChooser(
                            Intent(Intent.ACTION_SEND).apply {
                                type = "application/pdf"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            },
                            "Share Prescription"
                        ))
                    }

                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(file: File) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, file.name)
                    put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                    put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/MediHive")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { output ->
                        file.inputStream().use { input -> input.copyTo(output) }
                    }
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, values, null, null)
                }
            } else {
                val dir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                val mediHiveDir = File(dir, "MediHive")
                mediHiveDir.mkdirs()
                val dest = File(mediHiveDir, file.name)
                file.copyTo(dest, overwrite = true)
            }
        } catch (_: Exception) { }
    }
}
