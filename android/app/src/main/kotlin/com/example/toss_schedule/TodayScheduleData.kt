package com.example.toss_schedule

import android.content.SharedPreferences
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Snapshot includes templates and overrides, so midnight does not need Flutter running. */
object TodayScheduleData {
    fun load(data: SharedPreferences): List<JSONObject> {
        return try {
            val snapshot = JSONObject(data.getString("schedule_snapshot", "{}").orEmpty())
            val now = Calendar.getInstance()
            val date = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
            val day = (now.get(Calendar.DAY_OF_WEEK) + 5) % 7
            val custom = snapshot.optJSONArray("customized_dates")
            val customized = custom != null && (0 until custom.length()).any { custom.optString(it) == date }
            val all = snapshot.optJSONArray("schedules") ?: return emptyList()
            (0 until all.length()).map { all.getJSONObject(it) }.filter {
                if (customized) it.optString("date") == date
                else it.isNull("date") && it.optInt("day_of_week") == day
            }.sortedBy { it.optInt("start_hour") * 60 + it.optInt("start_minute") }
        } catch (_: Exception) { emptyList() }
    }

    fun dateLabel(): String {
        val now = Calendar.getInstance()
        val days = listOf("월", "화", "수", "목", "금", "토", "일")
        return "${now.get(Calendar.MONTH) + 1}월 ${now.get(Calendar.DAY_OF_MONTH)}일 (${days[(now.get(Calendar.DAY_OF_WEEK) + 5) % 7]})"
    }

    fun time(row: JSONObject): String = String.format(Locale.US, "%02d:%02d–%02d:%02d",
        row.optInt("start_hour"), row.optInt("start_minute"), row.optInt("end_hour"), row.optInt("end_minute"))
}
