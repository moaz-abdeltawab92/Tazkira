import 'package:tazkira_app/core/routing/route_export.dart';

class ContactMeSection extends StatelessWidget {
  const ContactMeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A6B5C), Color(0xFF6DBE9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'للتواصل والاقتراحات كلمني على حساباتي',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14.h),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SocialIconDesign(
                socialLink: "https://wa.me/+201017645365",
                iconUrl: 'assets/icons/whatsapp.png',
              ),
              SocialIconDesign(
                socialLink: "https://www.linkedin.com/in/moaz-ayman-a59230296/",
                iconUrl: 'assets/icons/linkedin.png',
              ),
              SocialIconDesign(
                socialLink: "https://www.facebook.com/share/1XKarLmjTS/",
                iconUrl: 'assets/icons/facebook.png',
              ),
              SocialIconDesign(
                socialLink:
                    "https://www.instagram.com/moaz_abdeltawab?igsh=eW41Y2x1ODh6MGp4&utm_source=qr",
                iconUrl: 'assets/icons/insta.png',
              ),
              SocialIconDesign(
                socialLink: "mailto:moazayman128@gmail.com",
                iconUrl: 'assets/icons/gmail.png',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
