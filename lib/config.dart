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

/// Chave do login.
///
/// `false` = MODO SEM LOGIN (temporário, a pedido do professor): a tela de
/// login mostra só a escolha do perfil e entra direto, sem e-mail nem senha.
/// O servidor precisa estar com `SEM_LOGIN=true` e `SEM_LOGIN_CHAVE` igual a
/// `semLoginChave` abaixo (variáveis de ambiente na Vercel).
///
/// `true` = login normal no servidor, como antes.
const bool loginAtivo = true;

/// Mesma chave configurada em `SEM_LOGIN_CHAVE` no servidor. Só vale no modo
/// sem login; é uma chave de teste, não publique o app com ela.
const String semLoginChave = '315dcf8e98fb0e80faca8d187e94fe9044ecf5b9fadc00d1';

/// Tamanho máximo de um documento enviado (item 08 da Etapa 3). O servidor
/// aceita até 10 MB, mas a Vercel limita o corpo de uma requisição a cerca de
/// 4,5 MB, então o app barra acima de 4 MB antes de enviar.
const int limiteUploadBytes = 4 * 1024 * 1024;
