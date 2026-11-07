package com.example.toss_schedule

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/** Collection fallback for Android versions before RemoteCollectionItems (API 31). */
class TodayScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    class Factory(private val context: Context) : RemoteViewsFactory {
        private var rows = emptyList<JSONObject>()
        override fun onCreate() { onDataSetChanged() }
        override fun onDataSetChanged() { rows = TodayScheduleData.load(HomeWidgetPlugin.getData(context)) }
        override fun onDestroy() { rows = emptyList() }
        override fun getCount() = rows.size
        override fun getViewAt(position: Int): RemoteViews? = rows.getOrNull(position)?.let { rowView(context, it) }
        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = rows[position].optLong("id", position.toLong())
        override fun hasStableIds() = true
    }

    companion object {
        fun rowView(context: Context, row: JSONObject): RemoteViews =
            RemoteViews(context.packageName, R.layout.today_schedule_widget_row).apply {
                setTextViewText(R.id.widget_row_time, TodayScheduleData.time(row))
                setTextViewText(R.id.widget_row_title, row.optString("title"))
                setTextViewText(R.id.widget_row_memo, row.optString("memo"))
                setViewVisibility(R.id.widget_row_memo,
                    if (row.optString("memo").isBlank()) android.view.View.GONE else android.view.View.VISIBLE)
                setOnClickFillInIntent(R.id.widget_row_root, Intent())
            }
    }
}
