import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

final privacyPolicyUrl = Uri.parse('$siteUrl/privacy');

/// Opens a page from the StaycationPro website in an in-app browser.
Future<void> openSitePage(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }
}
