import 'dart:io';

Future<bool> probeDnsReachability() async {
  try {
    final lookup = await InternetAddress.lookup('dns.google')
        .timeout(const Duration(seconds: 3));
    return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
