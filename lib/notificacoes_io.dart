import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();
bool _iniciado = false;

Future<bool> _iniciar() async {
  if (_iniciado) return true;
  try {
    const configuracao = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(configuracao);
    _iniciado = true;
    return true;
  } catch (_) {
    return false;
  }
}

/// Android 13+ exige permissão em tempo de execução (POST_NOTIFICATIONS).
Future<bool> pedirPermissao() async {
  if (!await _iniciar()) return false;
  try {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final concedida = await android?.requestNotificationsPermission();
    return concedida ?? true;
  } catch (_) {
    return false;
  }
}

Future<bool> mostrar(String titulo, String corpo) async {
  if (!await _iniciar()) return false;
  try {
    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'envio_documentos',
        'Envio de documentos',
        channelDescription: 'Avisos sobre documentos enviados ao servidor.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      titulo,
      corpo,
      detalhes,
    );
    return true;
  } catch (_) {
    return false;
  }
}
