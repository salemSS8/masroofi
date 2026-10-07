package com.example.bashnddof

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentProvider
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.UriMatcher
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * مزود المحتوى الآمن (ContentProvider) للتكامل بين تطبيقي (مصروفي) و (وصاة)
 * يسمح لتطبيق وصاة المعتمد بالاستعلام عن قائمة الأظرف المالية وخصم المصروفات المعتمدة صامتاً
 */
class MasroufiProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "com.example.bashnddof.provider"
        val CONTENT_URI_ENVELOPES: Uri = Uri.parse("content://$AUTHORITY/envelopes")
        val CONTENT_URI_TRANSACTIONS: Uri = Uri.parse("content://$AUTHORITY/transactions")
        val CONTENT_URI_STATUS: Uri = Uri.parse("content://$AUTHORITY/status")

        private const val CODE_ENVELOPES = 1
        private const val CODE_TRANSACTIONS = 2
        private const val CODE_STATUS = 3

        private val uriMatcher = UriMatcher(UriMatcher.NO_MATCH).apply {
            addURI(AUTHORITY, "envelopes", CODE_ENVELOPES)
            addURI(AUTHORITY, "transactions", CODE_TRANSACTIONS)
            addURI(AUTHORITY, "status", CODE_STATUS)
        }

        private const val NOTIF_CHANNEL_ID = "masroufi_integration_channel"
        private const val NOTIF_CHANNEL_NAME = "تنبيهات تكامل وصاة ومصروفي"
    }

    private fun getAppDatabase(): SQLiteDatabase? {
        val ctx = context ?: return null
        val dbFile = ctx.getDatabasePath("bashnddof.db")
        if (!dbFile.exists()) {
            return null
        }
        return try {
            SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onCreate(): Boolean {
        createNotificationChannel()
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? {
        val db = getAppDatabase() ?: return null

        return when (uriMatcher.match(uri)) {
            CODE_ENVELOPES -> {
                val sql = """
                    SELECT 
                        e.id AS _id,
                        e.id AS id,
                        e.name AS name,
                        e.allocated_amount AS allocated_amount,
                        e.icon AS icon,
                        e.color AS color,
                        COALESCE(SUM(t.amount), 0.0) AS spent_amount,
                        (e.allocated_amount - COALESCE(SUM(t.amount), 0.0)) AS remaining_amount
                    FROM envelopes e
                    LEFT JOIN transactions t ON t.envelope_id = e.id AND t.type = 'expense'
                    GROUP BY e.id, e.name, e.allocated_amount, e.icon, e.color
                    ORDER BY e.name ASC
                """.trimIndent()
                db.rawQuery(sql, null)
            }
            CODE_STATUS -> {
                // فحص حالة الاتصال والربط
                val sql = "SELECT COUNT(*) as count FROM envelopes"
                db.rawQuery(sql, null)
            }
            else -> null
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        if (uriMatcher.match(uri) != CODE_TRANSACTIONS || values == null) {
            return null
        }

        val db = getAppDatabase() ?: return null

        val title = values.getAsString("title") ?: "مصروف عائلي"
        val amount = values.getAsDouble("amount") ?: 0.0
        val envelopeId = values.getAsInteger("envelope_id")
        val categoryId = values.getAsInteger("category_id")
        val notes = values.getAsString("notes") ?: "معتمد عبر تطبيق وصاة"

        val now = Date()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)

        val transactionValues = ContentValues().apply {
            put("title", title)
            put("amount", amount)
            put("type", "expense")
            if (categoryId != null) put("category_id", categoryId)
            if (envelopeId != null) put("envelope_id", envelopeId)
            put("date", dateFormat.format(now))
            put("notes", notes)
            put("created_at", isoFormat.format(now))
            put("is_recurring", 0)
        }

        val id = db.insert("transactions", null, transactionValues)
        if (id > 0) {
            // جلب اسم الظرف لعرضه في الإشعار
            var envelopeName = ""
            if (envelopeId != null) {
                val cursor = db.rawQuery("SELECT name FROM envelopes WHERE id = ?", arrayOf(envelopeId.toString()))
                if (cursor.moveToFirst()) {
                    envelopeName = cursor.getString(0) ?: ""
                }
                cursor.close()
            }

            // إرسال إشعار فوري لرب الأسرة بتأكيد الخصم
            showDeductionNotification(title, amount, envelopeName)

            return ContentUris.withAppendedId(CONTENT_URI_TRANSACTIONS, id)
        }

        return null
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun getType(uri: Uri): String? {
        return when (uriMatcher.match(uri)) {
            CODE_ENVELOPES -> "vnd.android.cursor.dir/vnd.com.example.bashnddof.envelopes"
            CODE_TRANSACTIONS -> "vnd.android.cursor.item/vnd.com.example.bashnddof.transactions"
            else -> null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ctx = context ?: return
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                NOTIF_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات المعاملات والمصروفات المعتمدة آلياً من تطبيق وصاة"
                enableVibration(true)
            }
            val manager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun showDeductionNotification(title: String, amount: Double, envelopeName: String) {
        val ctx = context ?: return
        try {
            val manager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            val body = if (envelopeName.isNotEmpty()) {
                "تم تسجيل مصروف \"$title\" بمبلغ ${String.format(Locale.US, "%.0f", amount)} ريال من ظرف \"$envelopeName\" (اعتماد وصاة)"
            } else {
                "تم تسجيل مصروف \"$title\" بمبلغ ${String.format(Locale.US, "%.0f", amount)} ريال (اعتماد وصاة)"
            }

            // محاولة جلب أيقونة الإشعارات الصغيرة
            val iconResId = ctx.resources.getIdentifier("ic_notification", "drawable", ctx.packageName)
            val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info

            val notif = NotificationCompat.Builder(ctx, NOTIF_CHANNEL_ID)
                .setSmallIcon(smallIcon)
                .setContentTitle("مصروفي | اعتماد مصروف جديد")
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            manager.notify((System.currentTimeMillis() % 100000).toInt(), notif)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
