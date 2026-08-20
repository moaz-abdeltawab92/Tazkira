package com.moaz.tazkira.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.moaz.tazkira.MainActivity

/**
 * Jetpack Glance home screen widget for Tazkira.
 *
 * Visual hierarchy (matches iOS design language):
 *  1. "الصلاة القادمة"  ← small caption
 *  2. Next prayer name (large bold) + time (semibold)
 *  3. Five prayer columns in one RTL row
 *  4. Hijri date (if available)
 *
 * Background: teal gradient drawable (widget_background.xml).
 * All text: white. Active prayer: bold. Others: regular + reduced alpha.
 * No inner cards, no borders, no decorative elements.
 *
 * Note on typography: Jetpack Glance renders on top of RemoteViews, which
 * does not support loading custom TTF fonts from res/font/. The fontFamily
 * parameter in Glance TextStyle only resolves system-installed fonts.
 * All text therefore renders with the system default font. The Cairo TTF
 * files are retained in res/font/ for potential future use (e.g. if Glance
 * adds bundled font support) and for the main Flutter app.
 */
class PrayerGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val snapshot = SnapshotReader.read(context)
            WidgetContent(snapshot = snapshot)
        }
    }

    // -------------------------------------------------------------------------
    // Root composable
    // -------------------------------------------------------------------------

    @Composable
    private fun WidgetContent(snapshot: PrayerSnapshot?) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(androidx.glance.ImageProvider(com.moaz.tazkira.R.drawable.widget_background))
                .clickable(actionStartActivity<MainActivity>())
                .padding(horizontal = 12.dp, vertical = 10.dp),
            contentAlignment = Alignment.TopEnd
        ) {
            if (snapshot == null) {
                PlaceholderContent()
            } else {
                MainContent(snapshot = snapshot)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Main content
    // -------------------------------------------------------------------------

    @Composable
    private fun MainContent(snapshot: PrayerSnapshot) {
        val currentDate = java.time.LocalDate.now().toString()
        val useTomorrow = currentDate == snapshot.tomorrowDate && snapshot.tomorrowDate.isNotEmpty()
        val useToday = currentDate == snapshot.date || snapshot.date.isEmpty()
        val stale = PrayerFormatters.isStale(snapshot.snapshotTimestamp) || (!useToday && !useTomorrow)
        
        val activeFajr = if (useTomorrow) snapshot.tomorrowFajr else snapshot.fajr
        val activeDhuhr = if (useTomorrow) snapshot.tomorrowDhuhr else snapshot.dhuhr
        val activeAsr = if (useTomorrow) snapshot.tomorrowAsr else snapshot.asr
        val activeMaghrib = if (useTomorrow) snapshot.tomorrowMaghrib else snapshot.maghrib
        val activeIsha = if (useTomorrow) snapshot.tomorrowIsha else snapshot.isha
        val activeHijri = if (useTomorrow) snapshot.tomorrowHijriDate else snapshot.hijriDate

        val isRtl = androidx.glance.LocalContext.current.resources.configuration.layoutDirection == android.view.View.LAYOUT_DIRECTION_RTL
        
        val nextPrayerInfo = determineNextPrayer(snapshot)
        val nextName = nextPrayerInfo.first
        val nextTime = nextPrayerInfo.second

        Column(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.End
        ) {

            // ── 1. Caption ─────────────────────────────────────────────
            Text(
                text = "الصلاة القادمة",
                style = TextStyle(
                    color = ColorProvider(Color.White.copy(alpha = 0.75f)),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Normal,
                    textAlign = TextAlign.End
                ),
                modifier = GlanceModifier.fillMaxWidth()
            )

            // ── 2. Next prayer name + time ─────────────────────────────
            Row(
                modifier = GlanceModifier.fillMaxWidth().padding(top = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (isRtl) {
                    Text(
                        text = nextName,
                        style = TextStyle(
                            color = ColorProvider(
                                if (stale) Color.White.copy(alpha = 0.6f)
                                else Color.White
                            ),
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.End
                        )
                    )

                    Spacer(modifier = GlanceModifier.width(6.dp))

                    Text(
                        text = PrayerFormatters.formatTime(nextTime),
                        style = TextStyle(
                            color = ColorProvider(
                                if (stale) Color.White.copy(alpha = 0.5f)
                                else Color.White.copy(alpha = 0.85f)
                            ),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            textAlign = TextAlign.End
                        )
                    )

                    Spacer(modifier = GlanceModifier.width(0.dp).defaultWeight())
                } else {
                    Spacer(modifier = GlanceModifier.width(0.dp).defaultWeight())

                    Text(
                        text = PrayerFormatters.formatTime(nextTime),
                        style = TextStyle(
                            color = ColorProvider(
                                if (stale) Color.White.copy(alpha = 0.5f)
                                else Color.White.copy(alpha = 0.85f)
                            ),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            textAlign = TextAlign.End
                        )
                    )

                    Spacer(modifier = GlanceModifier.width(6.dp))

                    Text(
                        text = nextName,
                        style = TextStyle(
                            color = ColorProvider(
                                if (stale) Color.White.copy(alpha = 0.6f)
                                else Color.White
                            ),
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.End
                        )
                    )
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            // ── 3. Five prayer columns ─────────────────────────────────
            PrayerRow(
                fajr = activeFajr,
                dhuhr = activeDhuhr,
                asr = activeAsr,
                maghrib = activeMaghrib,
                isha = activeIsha,
                activePrayerName = nextName,
                stale = stale,
                isRtl = isRtl
            )

            // ── 4. Hijri date (if available) ───────────────────────────
            if (activeHijri.isNotEmpty()) {
                Text(
                    text = activeHijri,
                    style = TextStyle(
                        color = ColorProvider(Color.White.copy(alpha = 0.7f)),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Normal,
                        textAlign = TextAlign.End
                    ),
                    modifier = GlanceModifier.fillMaxWidth().padding(top = 4.dp)
                )
            }
        }
    }

    // -------------------------------------------------------------------------
    // Prayer row
    // -------------------------------------------------------------------------

    @Composable
    private fun PrayerRow(
        fajr: String,
        dhuhr: String,
        asr: String,
        maghrib: String,
        isha: String,
        activePrayerName: String,
        stale: Boolean,
        isRtl: Boolean
    ) {
        val cells = listOf(
            Triple("الفجر", PrayerFormatters.formatTime(fajr), "الفجر"),
            Triple("الظهر", PrayerFormatters.formatTime(dhuhr), "الظهر"),
            Triple("العصر", PrayerFormatters.formatTime(asr), "العصر"),
            Triple("المغرب", PrayerFormatters.formatTime(maghrib), "المغرب"),
            Triple("العشاء", PrayerFormatters.formatTime(isha), "العشاء")
        )

        val orderedCells = if (isRtl) cells.reversed() else cells

        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            orderedCells.forEach { cell ->
                PrayerCell(
                    name = cell.first,
                    time = cell.second,
                    isActive = activePrayerName == cell.third && !stale,
                    modifier = GlanceModifier.defaultWeight()
                )
            }
        }
    }

    @Composable
    private fun PrayerCell(
        name: String,
        time: String,
        isActive: Boolean,
        modifier: GlanceModifier
    ) {
        val nameColor = if (isActive) Color.White else Color.White.copy(alpha = 0.65f)
        val timeColor = if (isActive) Color.White else Color.White.copy(alpha = 0.5f)
        val weight    = if (isActive) FontWeight.Bold else FontWeight.Normal

        Column(
            modifier = modifier,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = name,
                style = TextStyle(
                    color = ColorProvider(nameColor),
                    fontSize = 10.sp,
                    fontWeight = weight,
                    textAlign = TextAlign.Center
                ),
                maxLines = 1
            )
            Text(
                text = time,
                style = TextStyle(
                    color = ColorProvider(timeColor),
                    fontSize = 10.sp,
                    fontWeight = weight,
                    textAlign = TextAlign.Center
                ),
                maxLines = 1
            )
        }
    }

    // -------------------------------------------------------------------------
    // Placeholder
    // -------------------------------------------------------------------------

    @Composable
    private fun PlaceholderContent() {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "تَذْكِرَة",
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
            )
            Spacer(modifier = GlanceModifier.height(6.dp))
            Text(
                text = "افتح التطبيق مرة واحدة لإعداد الويدجت",
                style = TextStyle(
                    color = ColorProvider(Color.White.copy(alpha = 0.75f)),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Normal,
                    textAlign = TextAlign.Center
                ),
                maxLines = 2
            )
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private fun determineNextPrayer(snapshot: PrayerSnapshot): Pair<String, String> {
        try {
            val now = java.time.Instant.now()
            val currentDate = java.time.LocalDate.now().toString()
            val useTomorrow = currentDate == snapshot.tomorrowDate && snapshot.tomorrowDate.isNotEmpty()

            val prayers = if (useTomorrow) {
                listOf(
                    Pair("الفجر", snapshot.tomorrowFajr),
                    Pair("الظهر", snapshot.tomorrowDhuhr),
                    Pair("العصر", snapshot.tomorrowAsr),
                    Pair("المغرب", snapshot.tomorrowMaghrib),
                    Pair("العشاء", snapshot.tomorrowIsha)
                )
            } else {
                listOf(
                    Pair("الفجر", snapshot.fajr),
                    Pair("الظهر", snapshot.dhuhr),
                    Pair("العصر", snapshot.asr),
                    Pair("المغرب", snapshot.maghrib),
                    Pair("العشاء", snapshot.isha)
                )
            }

            for (prayer in prayers) {
                if (prayer.second.isNotBlank()) {
                    val time = java.time.Instant.parse(prayer.second)
                    if (time.isAfter(now)) {
                        return prayer
                    }
                }
            }
            
            // Fallback: If today's prayers have all passed, next is tomorrow's Fajr.
            if (useTomorrow) {
                return Pair("الفجر", snapshot.tomorrowFajr)
            } else {
                if (snapshot.tomorrowFajr.isNotBlank()) {
                    return Pair("الفجر", snapshot.tomorrowFajr)
                }
                return Pair("الفجر", snapshot.fajr)
            }
        } catch (_: Exception) {
            // Safe fallback to the static values provided by Flutter if anything fails
            return Pair(snapshot.nextPrayerName, snapshot.nextPrayerTime)
        }
    }
}
