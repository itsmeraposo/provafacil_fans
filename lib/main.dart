import 'package:flutter/material.dart';

import 'screens/boas_vindas_screen.dart';
import 'theme.dart';

void main() {
  runApp(const ProvaFacilApp());
}

/// ProvaFácil FANS — etapa de navegação.
///
/// A tela inicial é a de boas-vindas, que leva ao login; dele o app direciona o usuário
/// para o painel do seu perfil (Professor, Direção ou Repografia), cada um
/// com seu próprio menu lateral, telas e fluxos de navegação.
class ProvaFacilApp extends StatelessWidget {
  const ProvaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProvaFácil FANS',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        final escala = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.25);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: escala),
          child: child!,
        );
      },
      home: const BoasVindasScreen(),
    );
  }
}
