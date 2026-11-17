import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> pedirPermissao() async {
  try {
    final atual = web.Notification.permission;
    if (atual == 'granted') return true;
    if (atual == 'denied') return false;
    final resposta = await web.Notification.requestPermission().toDart;
    return resposta.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

Future<bool> mostrar(String titulo, String corpo) async {
  try {
    if (web.Notification.permission != 'granted') return false;
    web.Notification(titulo, web.NotificationOptions(body: corpo));
    return true;
  } catch (_) {
    return false;
  }
}
