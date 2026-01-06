import 'dart:math';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_sabah_list.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_masaa_list.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_Istighfar_list.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_sleep.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_after_prayer.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_shukr_list.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_home.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_azan.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_Wudu.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_Istiqaz.dart';
import 'package:tazkira_app/features/azkar/presentation/data/azkar_masgd.dart';
import 'package:tazkira_app/features/doaa/presentation/data/doaa_list.dart';

class NotificationContentProvider {
  static final Random _random = Random();
  static String? _lastGeneralContent;

  static String getRandomMorningAzkar() {
    if (azkarAlsabah.isEmpty) return 'أذكار الصباح';
    return azkarAlsabah[_random.nextInt(azkarAlsabah.length)];
  }

  static String getRandomEveningAzkar() {
    if (azkarAlMasa.isEmpty) return 'أذكار المساء';
    return azkarAlMasa[_random.nextInt(azkarAlMasa.length)];
  }

  static String getRandomGeneralContent() {
    final List<String> allGeneralContent = [
      ...azkarIstighfar,
      ...doaaList,
      ...azkarSleep,
      ...azkarAfterPrayer,
      ...azkarShukrDhikr,
      ...azkarHome,
      ...azkarAzan,
      ...azkarWudu,
      ...azkarIstiqaz,
      ...azkarMasgd,
    ];

    if (allGeneralContent.isEmpty) return 'ذكر الله';

    String selectedContent;
    int attempts = 0;
    const maxAttempts = 50;

    do {
      selectedContent =
          allGeneralContent[_random.nextInt(allGeneralContent.length)];
      attempts++;
    } while (selectedContent == _lastGeneralContent &&
        attempts < maxAttempts &&
        allGeneralContent.length > 1);

    _lastGeneralContent = selectedContent;
    return selectedContent;
  }

  static String getSurahKahfReminder() {
    return 'لا تنسَ قراءة سورة الكهف ';
  }

  static String getSalatOnProphetReminder() {
    return 'أكثروا من الصلاة على النبي ﷺ ';
  }

  static String getMorningAzkarTitle() {
    return 'لا تنسَ قراءة أذكار الصباح ';
  }

  static String getEveningAzkarTitle() {
    return 'لا تنسَ قراءة أذكار المساء ';
  }

  static String getGeneralNotificationTitle() {
    return ' تَذْكِرَة ';
  }

  static String getFridayNotificationTitle() {
    return 'تذكير يوم الجمعة';
  }

  static String getSurahMulkReminder() {
    return '''‏كُل ليلة خُتمت بتلاوة سورة الملك، بشر لصاحبها في حياته بعودة قلبه للفطرة، وفي الآخرة بشفاعتها له.
قال رسول الله ﷺ :
«إِنَّ سُورَةً مِنَ القُرْآنِ ثَلاَثُونَ آيَةً شَفَعَتْ لِرَجُلٍ حَتَّى غُفِرَ لَهُ، وَهِيَ سُورَةُ تَبَارَكَ الَّذِي بِيَدِهِ المُلْكُ»''';
  }

  static String getBeforeSleepDhikr() {
    return '''« نام وأنت مغفور الذنب »

‏من قال حين يأوي إلى فراشه:
لا إله إلا الله وحده لا شريك له،له الملك وله الحمد وهو على كل شيء قدير
لاحول ولا قوةً إلا بالله
سبحان الله والحمدلله
 ولا إله إلا الله والله أكبر
‏غفر الله ذنوبه وإن كانت مثل زبد البحر''';
  }

  static String getPrayerReminderText(String prayerName) {
    return 'تبقّى 10 دقائق على صلاة $prayerName ';
  }
}
