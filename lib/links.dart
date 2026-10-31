import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

final privacyPolicyUrl = Uri.parse('$siteUrl/privacy');

/// The website's deletion page, with the account email filled in.
Uri deleteAccountUrl(String email) => Uri.parse(
  '$siteUrl/delete-account',
).replace(queryParameters: {if (email.isNotEmpty) 'email': email});

/// Opens a page from the StaycationPro website.
Future<void> openSitePage(
  BuildContext context,
  Uri url, {
  LaunchMode mode = LaunchMode.inAppBrowserView,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(url, mode: mode);
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }
}
