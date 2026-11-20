import 'package:url_launcher/url_launcher.dart';

const youtubeChannel = 'https://www.youtube.com/@mircoschroeder1';

Future<void> openYoutubeChannel() =>
    launchUrl(Uri.parse(youtubeChannel), mode: LaunchMode.externalApplication);
