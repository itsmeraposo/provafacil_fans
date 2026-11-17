import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api.dart';
import 'app_state.dart';
import 'arquivos.dart';
import 'preferencias.dart';
import 'models.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/direcao/painel_direcao_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pdf_visualizador_screen.dart';
import 'screens/professor/painel_professor_screen.dart';
import 'screens/repografia/painel_repografia_screen.dart';
import 'theme.dart';
import 'widgets/banner_offline.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
  // No modo offline (entrou sem conexão), tenta abrir a sessão de novo antes
  // de falar com o servidor.
  ApiClient.instancia.aoFaltarSessao = AppState.instancia.garantirSessao;
  // Avisa na tela quando algo guardado no aparelho é enviado sozinho.
  AppState.instancia.aoAvisar = (mensagem) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  };
  // PDF/DOCX pedido sem conexão: quando fica pronto, avisa com botão "Abrir".
  AppState.instancia.aoArquivoPronto = (bytes, titulo, formato) {
    final nome = Arquivos.nome(titulo, formato);
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 30),
        content: Text('${formato.toUpperCase()} da prova "$titulo" pronto.'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            if (formato != 'pdf') {
              Arquivos.compartilhar(bytes, nome, mime: mimeDocx);
            } else if (kIsWeb) {
              Arquivos.visualizarPdf(bytes, nome);
            } else {
              navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (_) =>
                    PdfVisualizadorScreen(bytes: bytes, nome: nome),
              ));
            }
          },
        ),
      ));
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
      title: 'Prova Fácil',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
              child: MoldeOffline(child: child!),
            );
          },
        );
      },
      home: const _TelaInicial(),
    );
  }
}

/// Primeira tela: se havia um login guardado no aparelho (token em
/// armazenamento seguro) e o servidor ainda o aceita, abre direto o painel do
/// perfil; senão mostra as boas-vindas, que levam ao login.
class _TelaInicial extends StatefulWidget {
  const _TelaInicial();

  @override
  State<_TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<_TelaInicial> {
  late final Future<bool> _restauracao = AppState.instancia
      .restaurarSessao()
      .timeout(const Duration(seconds: 15), onTimeout: () => false)
      .catchError((_) => false);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restauracao,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final usuario = AppState.instancia.usuarioAtual;
        if (resultado.data == true && usuario != null) {
          return switch (usuario.perfil) {
            Perfil.professor => const PainelProfessorScreen(),
            Perfil.direcao => const PainelDirecaoScreen(),
            Perfil.repografia => const PainelRepografiaScreen(),
          };
        }
        return const BoasVindasScreen();
      },
    );
  }
}
