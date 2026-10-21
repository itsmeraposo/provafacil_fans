import 'package:flutter/material.dart';

import 'api.dart';
import 'app_state.dart';
import 'preferencias.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferencias.carregar();

  // Se o servidor derrubar a sessão (expirou), volta para o login.
  ApiClient.instancia.aoSessaoExpirada = () {
    AppState.instancia.sessaoExpirada();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (rota) => false,
    );
  };
  runApp(const ProvaFacilApp());
}

/// ProvaFácil FANS — app integrado à API do servidor.
///
/// A tela inicial é a de boas-vindas, que leva ao login; dele o app direciona
/// o usuário para o painel do seu perfil (Professor, Direção ou Repografia),
/// cada um com seu próprio menu lateral, telas e fluxos de navegação.
class ProvaFacilApp extends StatelessWidget {
  const ProvaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProvaFácil FANS',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: Preferencias.textoGrande,
          builder: (context, grande, _) {
            final escala = grande
                ? const TextScaler.linear(1.25)
                : MediaQuery.textScalerOf(context)
                    .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.25);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: escala),
              child: child!,
            );
          },
        );
      },
      home: const BoasVindasScreen(),
    );
  }
}
