package ir.namayeshyar.namayeshyar

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val OPEN_FILE_CHANNEL = "ir.hesabchi/open_json"
    }

    private var openFileChannel: MethodChannel? = null
    private var initialOpenFile: Uri? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialOpenFile = extractJsonUri(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        openFileChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OPEN_FILE_CHANNEL,
        )
        openFileChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialOpenFile" -> {
                    val file = initialOpenFile
                    initialOpenFile = null
                    result.success(file?.let(::filePayload))
                }
                "readOpenFile" -> readOpenFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val file = extractJsonUri(intent) ?: return
        initialOpenFile = file
        openFileChannel?.invokeMethod("openFile", filePayload(file))
    }

    private fun readOpenFile(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("uri")
        val uri = text?.let(Uri::parse)
        if (uri == null) {
            result.error("invalid_uri", "نشانی فایل معتبر نیست.", null)
            return
        }
        try {
            val bytes = if (uri.scheme == "file") {
                val path = uri.path ?: throw IllegalArgumentException("مسیر فایل موجود نیست.")
                File(path).readBytes()
            } else {
                contentResolver.openInputStream(uri)?.use { it.readBytes() }
            }
            if (bytes == null) {
                result.error("unreadable_file", "امکان خواندن فایل وجود ندارد.", null)
                return
            }
            result.success(bytes)
        } catch (error: Exception) {
            result.error("unreadable_file", "امکان خواندن فایل وجود ندارد.", error.message)
        }
    }

    private fun extractJsonUri(intent: Intent?): Uri? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: intent.clipData?.getItemAt(0)?.uri ?: return null
        val type = intent.type?.lowercase().orEmpty()
        val name = displayName(uri).lowercase()
        return if (
            name.endsWith(".hch") ||
                name.endsWith(".json") ||
                type == "application/x-hesabchi" ||
                type == "application/json" ||
                type == "text/json" ||
                type == "application/octet-stream"
        ) {
            uri
        } else {
            null
        }
    }

    private fun filePayload(uri: Uri): Map<String, String> = mapOf(
        "uri" to uri.toString(),
        "name" to displayName(uri),
    )

    private fun displayName(uri: Uri): String {
        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
            if (cursor?.moveToFirst() == true) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) return cursor.getString(index)
            }
        } catch (_: Exception) {
            // بعضی فایل‌منیجرهای قدیمی نام فایل را در provider عرضه نمی‌کنند.
        } finally {
            cursor?.close()
        }
        return uri.lastPathSegment?.substringAfterLast('/') ?: "hesabchi_data.hch"
    }
}
