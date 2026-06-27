/// Pure builders for standard QR payload strings (no widget/encoding concerns).
abstract final class QrPayloads {
  static String url(String url) => url;

  static String text(String value) => value;

  static String phone(String number) => 'tel:$number';

  static String sms(String number, {String? message}) =>
      'SMSTO:$number:${message ?? ''}';

  static String location(double lat, double lng) => 'geo:$lat,$lng';

  static String email(String to, {String? subject, String? body}) {
    final params = <String>[
      if (subject != null) 'subject=${_enc(subject)}',
      if (body != null) 'body=${_enc(body)}',
    ];
    return params.isEmpty ? 'mailto:$to' : 'mailto:$to?${params.join('&')}';
  }

  static String wifi({
    required String ssid,
    String? password,
    String security = 'WPA',
    bool hidden = false,
  }) {
    final s = _wifiEsc(ssid);
    final p = password == null ? '' : _wifiEsc(password);
    return 'WIFI:T:$security;S:$s;P:$p;H:$hidden;;';
  }

  static String contact(Map<String, String> f) {
    final lines = <String>['BEGIN:VCARD', 'VERSION:3.0'];
    if (f['name'] != null) lines.add('FN:${f['name']}');
    if (f['org'] != null) lines.add('ORG:${f['org']}');
    if (f['title'] != null) lines.add('TITLE:${f['title']}');
    if (f['phone'] != null) lines.add('TEL:${f['phone']}');
    if (f['email'] != null) lines.add('EMAIL:${f['email']}');
    if (f['url'] != null) lines.add('URL:${f['url']}');
    if (f['address'] != null) lines.add('ADR:${f['address']}');
    lines.add('END:VCARD');
    return lines.join('\n');
  }

  static String calendar(Map<String, String> f) {
    final lines = <String>['BEGIN:VEVENT'];
    if (f['summary'] != null) lines.add('SUMMARY:${f['summary']}');
    if (f['location'] != null) lines.add('LOCATION:${f['location']}');
    if (f['start'] != null) lines.add('DTSTART:${f['start']}');
    if (f['end'] != null) lines.add('DTEND:${f['end']}');
    if (f['description'] != null) lines.add('DESCRIPTION:${f['description']}');
    lines.add('END:VEVENT');
    return lines.join('\n');
  }

  // ---- internals ----

  /// Encodes a query-string component: spaces become %20, & becomes %26, etc.
  /// [Uri.encodeQueryComponent] encodes space as '+'; we replace '+' with '%20'.
  /// Confirmed on Dart SDK: encodeQueryComponent('Hi there') == 'Hi+there',
  /// encodeQueryComponent('a&b') == 'a%26b'.
  static String _enc(String s) =>
      Uri.encodeQueryComponent(s).replaceAll('+', '%20');

  /// Escapes WiFi special chars: \ ; , : " → prefixed with backslash.
  static String _wifiEsc(String s) => s.replaceAllMapped(
        RegExp(r'([\\;,:"])'),
        (m) => '\\${m[1]}',
      );
}
