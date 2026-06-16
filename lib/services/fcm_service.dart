import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FcmService {
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';
  static const _projectId = 'rapilead-b41b9';

  // Obtiene un token OAuth2 desde la service account
  static Future<String> _getAccessToken() async {
    final jsonStr = await rootBundle.loadString('assets/service_account.json');
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(jsonStr),
    );
    final client = await clientViaServiceAccount(
      credentials,
      [_fcmScope],
    );
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  static Future<void> notificarAdmins({
    required String titulo,
    required String cuerpo,
  }) async {
    try {
      // 1. Obtener tokens FCM de los admins desde Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'Administrador')
          .get();

      final tokens = <String>[];
      for (final doc in snapshot.docs) {
        final fcmTokens = doc.data()['fcmTokens'];
        if (fcmTokens is List) {
          tokens.addAll(fcmTokens.cast<String>());
        }
      }

      if (tokens.isEmpty) return;

      // 2. Obtener token OAuth2
      final accessToken = await _getAccessToken();

      // 3. Enviar una notificación por cada token (V1 no soporta multicast)
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      for (final token in tokens) {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {
                'title': titulo,
                'body': cuerpo,
              },
            },
          }),
        );
      }
    } catch (e) {
      debugPrint('FcmService error: $e');
    }
  }
}
