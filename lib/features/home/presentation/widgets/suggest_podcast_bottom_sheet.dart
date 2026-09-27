import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/home/presentation/data/podcast_suggestion_service.dart';

class SuggestPodcastBottomSheet extends StatefulWidget {
  const SuggestPodcastBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SuggestPodcastBottomSheet(),
    );
  }

  @override
  State<SuggestPodcastBottomSheet> createState() =>
      _SuggestPodcastBottomSheetState();
}

class _SuggestPodcastBottomSheetState extends State<SuggestPodcastBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await PodcastSuggestionService.sendSuggestion(
      title: _titleController.text,
      url: _urlController.text,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اقتراحك وصلنا بنجاح هنراجعه ونضيفه في أسرع وقت🤍',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14.sp),
          ),
          backgroundColor: const Color(0xFF5A9A8E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ في الإرسال، يُرجى المحاولة مرة أخرى.',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14.sp),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 24.h,
          bottom: 24.h + bottomInset,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26000000),
              blurRadius: 20.r,
              offset: Offset(0, -5.h),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: Color(0x1F5A9A8E),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: const Color(0xFF5A9A8E),
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'اقترح بودكاست أو قناة دينية',
                      style: GoogleFonts.cairo(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C4A45),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'شاركنا محتوى نافعاً لنتشارَك جميعاً الأجر، وسيتم مراجعته وإضافته لتَذْكِرَة .',
                  style: GoogleFonts.tajawal(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'اسم البودكاست أو القناة *',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يُرجى إدخال اسم البودكاست أو القناة';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'مثال: بودكاست وعي / السيرة النبوية',
                    hintStyle: GoogleFonts.tajawal(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFA),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFF5A9A8E)),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'رابط البودكاست أو القناة *',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يُرجى إدخال رابط البودكاست أو القناة';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'رابط يوتيوب / ساوندكلاود  ',
                    hintStyle: GoogleFonts.tajawal(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFA),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFF5A9A8E)),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'ملاحظات إضافية (اختياري)',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'أي تفاصيل أو ملاحظات تود إضافتها...',
                    hintStyle: GoogleFonts.tajawal(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFA),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: Color(0xFF5A9A8E)),
                    ),
                  ),
                ),
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9A8E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'إرسال الاقتراح 💡',
                            style: GoogleFonts.cairo(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
