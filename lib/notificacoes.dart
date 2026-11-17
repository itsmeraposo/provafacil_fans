// No Android usa o flutter_local_notifications; no navegador usa a API
// Notification do próprio navegador (o plugin não tem versão web).
import 'notificacoes_io.dart'
    if (dart.library.js_interop) 'notificacoes_web.dart' as plataforma;

/// Notificações locais do app (item 12 da Etapa 3).
class Notificacoes {
  Notificacoes._();

  /// Pede permissão para notificar. Chame a partir de um toque do usuário
  /// (o navegador só aceita o pedido assim). Devolve `false` se negada.
  static Future<bool> pedirPermissao() => plataforma.pedirPermissao();

  /// Mostra a notificação. Devolve `false` se não foi possível mostrar.
  static Future<bool> mostrar(String titulo, String corpo) =>
      plataforma.mostrar(titulo, corpo);
}
