package com.example.toss_schedule

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Renders today's timetable on the home screen. The Dart side writes the
/// already-formatted strings, so nothing here touches the database.
class TodayScheduleWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in listOf(Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager, manager.getAppWidgetIds(ComponentName(context, javaClass)))
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val rows = TodayScheduleData.load(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget).apply {
                setTextViewText(R.id.widget_date, TodayScheduleData.dateLabel())
                setTextViewText(R.id.widget_count, "오늘 일정 ${rows.size}개 ›")
                setEmptyView(R.id.widget_list, R.id.widget_empty)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val items = RemoteViews.RemoteCollectionItems.Builder().setHasStableIds(true).setViewTypeCount(1)
                    rows.forEachIndexed { index, row ->
                        items.addItem(row.optLong("id", index.toLong()), TodayScheduleWidgetService.rowView(context, row))
                    }
                    setRemoteAdapter(R.id.widget_list, items.build())
                } else {
                    val adapter = Intent(context, TodayScheduleWidgetService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        data = Uri.parse("scheduler://widget/$widgetId")
                    }
                    @Suppress("DEPRECATION")
                    setRemoteAdapter(R.id.widget_list, adapter)
                }
                val launch = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java,
                    Uri.parse("scheduler://today-schedules"))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    launch
                )
                setOnClickPendingIntent(R.id.widget_count, launch)
                setPendingIntentTemplate(R.id.widget_list, launch)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                @Suppress("DEPRECATION")
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
            }
        }
    }
}
