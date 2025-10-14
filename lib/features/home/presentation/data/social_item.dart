import 'package:tazkira_app/core/routing/route_export.dart';

class SocialIconDesign extends StatelessWidget {
  final String iconUrl;
  final String socialLink;
  const SocialIconDesign({
    super.key,
    required this.iconUrl,
    required this.socialLink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.w,
      height: 40.h,
      child: FloatingActionButton(
        heroTag: socialLink, // Unique hero tag using the social link
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          launchUrl(
            Uri.parse(socialLink),
          );
        },
        child: Image.asset(
          iconUrl,
          fit: BoxFit.cover,
          width: 32.w,
          height: 32.h,
        ),
      ),
    );
  }
}
