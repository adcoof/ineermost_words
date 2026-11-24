package app.airoleplay.ai_roleplay_chat

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * SAF（Storage Access Framework）桥：
 * - pickDirectory：系统目录选择器 + 持久化授权；
 * - list/read/write/delete/rename/move/exists：均以 tree Uri + 相对路径操作。
 *
 * 所有 I/O 在后台线程执行，结果回主线程。
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val REQ_PICK_DIR = 1001
        private const val REQ_SHIZUKU = 2001
    }

    private val channelName = "xinyu/saf"
    private var pendingPick: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK_DIR) return
        val result = pendingPick
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result?.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // 某些系统只授予临时权限，仍可当前会话使用。
        }
        val name = try {
            displayName(treeDocumentUri(uri))
        } catch (_: Exception) {
            "已授权文件夹"
        }
        result?.success(mapOf("uri" to uri.toString(), "name" to name))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> {
                        if (pendingPick != null) {
                            result.error("busy", "目录选择器已打开", null)
                            return@setMethodCallHandler
                        }
                        pendingPick = result
                        try {
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                                )
                            }
                            startActivityForResult(intent, REQ_PICK_DIR)
                        } catch (e: Exception) {
                            pendingPick = null
                            result.error("saf_error", e.message, null)
                        }
                    }
                    "list", "read", "write", "writeBytes", "delete", "rename", "move", "exists" -> {
                        val uri = call.argument<String>("uri")?.let { Uri.parse(it) }
                        if (uri == null) {
                            result.error("bad_args", "缺少 uri", null)
                            return@setMethodCallHandler
                        }
                        val path = call.argument<String>("path") ?: ""
                        runAsync(result) {
                            when (call.method) {
                                "list" -> list(uri, path)
                                "read" -> mapOf("bytes" to read(uri, path))
                                "write" -> {
                                    write(uri, path, call.argument<String>("content") ?: "")
                                    mapOf("ok" to true)
                                }
                                "writeBytes" -> {
                                    writeBytes(uri, path, call.argument<ByteArray>("bytes") ?: ByteArray(0))
                                    mapOf("ok" to true)
                                }
                                "delete" -> {
                                    delete(uri, path)
                                    mapOf("ok" to true)
                                }
                                "rename" -> {
                                    rename(uri, path, call.argument<String>("newName") ?: "")
                                    mapOf("ok" to true)
                                }
                                "move" -> {
                                    move(uri, path, call.argument<String>("to") ?: "")
                                    mapOf("ok" to true)
                                }
                                "exists" -> mapOf("exists" to (resolve(uri, path, false) != null))
                                else -> mapOf("ok" to false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xinyu/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val name = call.argument<String>("name")?.trim().orEmpty()
                        val content = call.argument<String>("content") ?: ""
                        if (name.isEmpty()) {
                            result.error("bad_args", "文件名不能为空", null)
                            return@setMethodCallHandler
                        }
                        runAsync(result) { saveToDownloads(name, content) }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xinyu/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(deviceStatus())
                    "requestShizuku" -> {
                        try {
                            if (!Shizuku.pingBinder()) {
                                throw IllegalStateException("Shizuku 未运行")
                            }
                            Shizuku.requestPermission(REQ_SHIZUKU)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("shizuku_error", e.message ?: "Shizuku 请求失败", null)
                        }
                    }
                    "shell" -> {
                        val command = call.argument<String>("command")?.trim().orEmpty()
                        if (command.isEmpty()) {
                            result.error("bad_args", "命令不能为空", null)
                        } else {
                            runAsync(result) { runShizukuShell(command) }
                        }
                    }
                    "uiText" -> result.success(XinyuAccessibilityService.instance?.screenText() ?: "")
                    "clickText" -> {
                        val text = call.argument<String>("text")?.trim().orEmpty()
                        if (text.isEmpty()) {
                            result.error("bad_args", "文字不能为空", null)
                        } else {
                            result.success(XinyuAccessibilityService.instance?.clickText(text) ?: false)
                        }
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shizukuAvailable(): Boolean = try {
        Shizuku.pingBinder()
    } catch (_: Throwable) {
        false
    }

    private fun shizukuGranted(): Boolean = try {
        shizukuAvailable() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Throwable) {
        false
    }

    private fun deviceStatus(): Map<String, Any> = mapOf(
        "shizukuAvailable" to shizukuAvailable(),
        "shizukuGranted" to shizukuGranted(),
        "accessibilityEnabled" to (XinyuAccessibilityService.instance != null),
    )

    /** 通过 Shizuku 的 shell 身份执行命令（input/am/screencap 等）。 */
    private fun runShizukuShell(command: String): Map<String, Any> {
        if (!shizukuGranted()) {
            throw IllegalStateException("Shizuku 未授权")
        }
        // API 13 把 newProcess 设为 private；同进程类加载器反射调用，
        // 若未来版本移除则抛错并提示用户。
        val process = try {
            val method = Shizuku::class.java.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java,
                Array<String>::class.java,
                String::class.java,
            )
            method.isAccessible = true
            method.invoke(null, arrayOf("sh", "-c", command), null, null) as Process
        } catch (e: Throwable) {
            throw IllegalStateException("Shizuku shell 不可用：${e.message}")
        }
        val stdout = StringBuilder()
        val stderr = StringBuilder()
        val outThread = Thread {
            process.inputStream.bufferedReader().use { stdout.append(it.readText()) }
        }
        val errThread = Thread {
            process.errorStream.bufferedReader().use { stderr.append(it.readText()) }
        }
        outThread.start()
        errThread.start()
        val finished = process.waitFor(20, TimeUnit.SECONDS)
        if (!finished) {
            process.destroy()
            throw IllegalStateException("命令超时（20s）")
        }
        outThread.join(1000)
        errThread.join(1000)
        return mapOf(
            "code" to process.exitValue(),
            "stdout" to stdout.take(8000),
            "stderr" to stderr.take(8000),
        )
    }

    /** 导出到公共「下载/心语Agent」；Android 10+ 走 MediaStore，无需存储权限。 */
    private fun saveToDownloads(name: String, content: String): Map<String, Any?> {
        val safe = name.replace(Regex("[\\\\/:*?\"<>|]"), "_").ifEmpty { "agent.txt" }
        val subDir = "心语Agent"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, safe)
                put(MediaStore.Downloads.MIME_TYPE, "text/plain; charset=utf-8")
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/$subDir",
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("无法创建下载文件")
            resolver.openOutputStream(uri)?.use {
                it.write(content.toByteArray(Charsets.UTF_8))
            } ?: throw IllegalStateException("无法写入下载文件")
            val done = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
            return mapOf(
                "uri" to uri.toString(),
                "path" to "Download/$subDir/$safe",
            )
        }
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            subDir,
        )
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("无法创建下载目录")
        }
        val file = File(dir, safe)
        file.writeText(content, Charsets.UTF_8)
        return mapOf("path" to file.absolutePath)
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        Thread {
            try {
                val value = block()
                Handler(Looper.getMainLooper()).post { result.success(value) }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("saf_error", e.message ?: e.javaClass.simpleName, null)
                }
            }
        }.start()
    }

    private fun treeDocumentUri(treeUri: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )

    private fun displayName(uri: Uri): String? {
        contentResolver.query(
            uri,
            arrayOf(Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(0)
        }
        return null
    }

    /** 逐段解析相对路径；allowMissing 时返回待创建的父目录信息。 */
    private fun resolve(treeUri: Uri, rawPath: String, createDirs: Boolean): Uri? {
        val path = rawPath.trim()
        var current = treeDocumentUri(treeUri)
        if (path.isEmpty() || path == ".") return current
        val segments = path.split('/').filter { it.isNotEmpty() && it != "." }
        for (segment in segments) {
            if (segment == "..") throw IllegalArgumentException("路径不允许包含 ..")
            val child = findChild(treeUri, current, segment)
            if (child != null) {
                current = child
                continue
            }
            if (!createDirs) return null
            val created = DocumentsContract.createDocument(
                contentResolver,
                current,
                Document.MIME_TYPE_DIR,
                segment,
            ) ?: throw IllegalStateException("无法创建目录：$segment")
            current = created
        }
        return current
    }

    private fun findChild(treeUri: Uri, parent: Uri, name: String): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getDocumentId(parent),
        )
        contentResolver.query(
            childrenUri,
            arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(1) == name) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        treeUri,
                        cursor.getString(0),
                    )
                }
            }
        }
        return null
    }

    private fun parentAndName(path: String): Pair<String, String> {
        val segments = path.split('/').filter { it.isNotEmpty() && it != "." }
        if (segments.isEmpty()) throw IllegalArgumentException("路径不能为空")
        val name = segments.last()
        if (name == ".." || name.contains('\u0000')) {
            throw IllegalArgumentException("文件名不合法")
        }
        return segments.dropLast(1).joinToString("/") to name
    }

    private fun list(treeUri: Uri, path: String): Map<String, Any> {
        val dir = resolve(treeUri, path, false)
            ?: throw IllegalArgumentException("目录不存在：$path")
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getDocumentId(dir),
        )
        val projection = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_MIME_TYPE,
            Document.COLUMN_SIZE,
            Document.COLUMN_LAST_MODIFIED,
        )
        val entries = mutableListOf<Map<String, Any?>>()
        contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val name = cursor.getString(1)
                val mime = cursor.getString(2)
                val relative = if (path.isEmpty() || path == ".") name else "$path/$name"
                entries.add(
                    mapOf(
                        "name" to name,
                        "path" to relative,
                        "isDir" to (mime == Document.MIME_TYPE_DIR),
                        "size" to if (cursor.isNull(3)) 0 else cursor.getLong(3),
                        "modified" to if (cursor.isNull(4)) null else cursor.getLong(4),
                    ),
                )
            }
        }
        entries.sortWith(compareBy({ it["isDir"] != true }, { it["name"] as String }))
        return mapOf("entries" to entries.take(200))
    }

    private fun read(treeUri: Uri, path: String): ByteArray {
        val uri = resolve(treeUri, path, false)
            ?: throw IllegalArgumentException("文件不存在：$path")
        contentResolver.openInputStream(uri)?.use { input ->
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(64 * 1024)
            var total = 0
            while (true) {
                val n = input.read(buffer)
                if (n <= 0) break
                total += n
                if (total > 2 * 1024 * 1024 + 1) break
                out.write(buffer, 0, n)
            }
            return out.toByteArray()
        }
        throw IllegalStateException("无法打开文件：$path")
    }

    private fun write(treeUri: Uri, path: String, content: String) {
        writeBytesInternal(treeUri, path, content.toByteArray(Charsets.UTF_8), "text/plain")
    }

    private fun writeBytes(treeUri: Uri, path: String, bytes: ByteArray) {
        writeBytesInternal(treeUri, path, bytes, mimeFor(path))
    }

    private fun writeBytesInternal(
        treeUri: Uri,
        path: String,
        bytes: ByteArray,
        mime: String,
    ) {
        val (parentPath, name) = parentAndName(path)
        val parent = resolve(treeUri, parentPath, true)
            ?: throw IllegalArgumentException("无法创建父目录")
        if (bytes.size > 10 * 1024 * 1024) {
            throw IllegalArgumentException("内容超过 10MB")
        }
        val existing = findChild(treeUri, parent, name)
        if (existing != null) {
            if (mimeType(existing) == Document.MIME_TYPE_DIR) {
                throw IllegalArgumentException("目标同名项是目录：$name")
            }
            contentResolver.openOutputStream(existing, "wt")?.use { it.write(bytes); it.flush() }
                ?: throw IllegalStateException("无法写入：$name")
            return
        }
        val created = DocumentsContract.createDocument(
            contentResolver,
            parent,
            mime,
            name,
        ) ?: throw IllegalStateException("无法创建文件：$name")
        contentResolver.openOutputStream(created, "wt")?.use { it.write(bytes); it.flush() }
            ?: throw IllegalStateException("无法写入：$name")
    }

    private fun mimeFor(path: String): String =
        when (path.substringAfterLast('.', "").lowercase()) {
            "png" -> "image/png"
            "jpg", "jpeg" -> "image/jpeg"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            "bmp" -> "image/bmp"
            "pdf" -> "application/pdf"
            "html", "htm" -> "text/html"
            "json" -> "application/json"
            "csv" -> "text/csv"
            else -> "application/octet-stream"
        }

    private fun delete(treeUri: Uri, path: String) {
        val uri = resolve(treeUri, path, false)
            ?: throw IllegalArgumentException("不存在：$path")
        if (!DocumentsContract.deleteDocument(contentResolver, uri)) {
            throw IllegalStateException("删除失败：$path")
        }
    }

    private fun rename(treeUri: Uri, path: String, newName: String) {
        if (newName.contains('/') || newName == "." || newName == ".." || newName.isBlank()) {
            throw IllegalArgumentException("新名称不合法")
        }
        val uri = resolve(treeUri, path, false)
            ?: throw IllegalArgumentException("不存在：$path")
        DocumentsContract.renameDocument(contentResolver, uri, newName)
            ?: throw IllegalStateException("重命名失败")
    }

    private fun mimeType(uri: Uri): String? =
        contentResolver.query(
            uri,
            arrayOf(Document.COLUMN_MIME_TYPE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }

    private fun move(treeUri: Uri, from: String, to: String) {
        val (fromParentPath, fromName) = parentAndName(from)
        val (targetParentPath, targetName) = parentAndName(to)
        val source = resolve(treeUri, from, false)
            ?: throw IllegalArgumentException("源不存在：$from")
        val sourceParent = resolve(treeUri, fromParentPath, false)
            ?: throw IllegalArgumentException("源目录不存在：$from")
        val targetParent = resolve(treeUri, targetParentPath, true)
            ?: throw IllegalArgumentException("无法创建目标目录")
        if (findChild(treeUri, targetParent, targetName) != null) {
            throw IllegalArgumentException("目标已存在：$to")
        }
        val sourceId = DocumentsContract.getDocumentId(source)
        val targetParentId = DocumentsContract.getDocumentId(targetParent)
        if (targetParentId == sourceId || targetParentId.startsWith("$sourceId/")) {
            throw IllegalArgumentException("不能移动到自身内部")
        }
        if (sourceParent == targetParent) {
            if (fromName != targetName) {
                DocumentsContract.renameDocument(contentResolver, source, targetName)
                    ?: throw IllegalStateException("重命名失败")
            }
            return
        }
        // 优先用系统 moveDocument，避免手工递归复制。
        try {
            val moved = DocumentsContract.moveDocument(
                contentResolver,
                source,
                sourceParent,
                targetParent,
            )
            if (moved != null) {
                if (fromName != targetName) {
                    DocumentsContract.renameDocument(contentResolver, moved, targetName)
                }
                return
            }
        } catch (_: Exception) {
            // 某些 provider 不支持 moveDocument，回退到复制+删除。
        }
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            sourceId,
        )
        val isDir = mimeType(source) == Document.MIME_TYPE_DIR
        if (isDir) {
            copyDirectory(treeUri, source, targetParent, targetName, children, 0)
        } else {
            val bytes = read(treeUri, from)
            write(treeUri, to, String(bytes, Charsets.UTF_8))
        }
        if (!DocumentsContract.deleteDocument(contentResolver, source)) {
            throw IllegalStateException("源删除失败：$from")
        }
    }

    private fun copyDirectory(
        treeUri: Uri,
        source: Uri,
        targetParent: Uri,
        targetName: String,
        children: Uri,
        depth: Int,
    ) {
        if (depth > 32) {
            throw IllegalStateException("目录层级过深，已停止复制")
        }
        val created = DocumentsContract.createDocument(
            contentResolver,
            targetParent,
            Document.MIME_TYPE_DIR,
            targetName,
        ) ?: throw IllegalStateException("无法创建目录：$targetName")
        contentResolver.query(
            children,
            arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_MIME_TYPE),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val childUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, cursor.getString(0))
                val childName = cursor.getString(1)
                val mime = cursor.getString(2)
                if (mime == Document.MIME_TYPE_DIR) {
                    copyDirectory(
                        treeUri,
                        childUri,
                        created,
                        childName,
                        DocumentsContract.buildChildDocumentsUriUsingTree(
                            treeUri,
                            cursor.getString(0),
                        ),
                        depth + 1,
                    )
                } else {
                    contentResolver.openInputStream(childUri)?.use { input ->
                        val out = DocumentsContract.createDocument(
                            contentResolver,
                            created,
                            "text/plain",
                            childName,
                        ) ?: throw IllegalStateException("无法创建文件：$childName")
                        contentResolver.openOutputStream(out, "wt")?.use { output ->
                            input.copyTo(output, 64 * 1024)
                        }
                    }
                }
            }
        }
    }
}
