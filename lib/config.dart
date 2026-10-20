/// Endereço do servidor (backend ProvaFácil: Node/Express + Firestore).
///
/// Escolha UMA das opções e deixe as outras comentadas:
///
/// 1) Emulador Android rodando o servidor no seu PC (`PORT=3001 npm start`):
///      http://10.0.2.2:3001
/// 2) Celular real por cabo USB, com o servidor no PC. Rode uma vez
///    `adb reverse tcp:3001 tcp:3001` e use:
///      http://localhost:3001
/// 3) Servidor publicado (ex.: Vercel). Troque pelo seu endereço https:
///      https://SEU-PROJETO.vercel.app
///
/// Sem barra no final.
const String apiBaseUrl = 'https://prova-facil-fans.vercel.app';
