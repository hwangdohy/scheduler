package com.example.toss_schedule

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Renders today's timetable on the home screen. The Dart side writes the
/// already-formatted strings, so nothing here touches the database.
class TodayScheduleWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val date = widgetData.getString("today_date", "").orEmpty()
        val count = widgetData.getString("today_count", "").orEmpty()
        val lines = widgetData.getString("today_lines", "").orEmpty()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget).apply {
                setTextViewText(R.id.widget_date, date)
                setTextViewText(R.id.widget_count, count)
                setTextViewText(
                    R.id.widget_lines,
                    if (lines.isBlank()) "오늘은 등록된 일정이 없어요" else lines
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
