import 'package:url_launcher/url_launcher.dart';
import '../utils/currency_formatter.dart';

class WhatsAppService {
  /// Clean phone number for India (+91)
  static String cleanPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = '91${clean.substring(1)}';
    }
    return clean;
  }

  /// Builds reminder message from template
  static String buildMessage({
    required String template,
    required String tenantName,
    required int amountDue,
    required String month,
    required String ownerName,
  }) {
    return template
        .replaceAll('{tenantName}', tenantName)
        .replaceAll('{amount}', CurrencyFormatter.format(amountDue))
        .replaceAll('{month}', month)
        .replaceAll('{ownerName}', ownerName);
  }

  /// Open WhatsApp with pre-filled message
  static Future<bool> sendWhatsAppReminder({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final encodedMessage = Uri.encodeComponent(message);

    // Try native WhatsApp URI first
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Open default SMS app
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      }
    } catch (_) {}
    return false;
  }

  /// Make direct phone call
  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final telUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri);
      }
    } catch (_) {}
    return false;
  }
}

