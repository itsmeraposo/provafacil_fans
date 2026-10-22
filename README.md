# ProvaFácil FANS — App Flutter (Etapa 2)

Aplicativo em **Flutter/Dart** para montar, revisar e imprimir provas da
Faculdade de Nova Serrana. Funciona no **Android** e no **navegador (web)** e
conversa por **HTTP** com uma API Node/Express que grava em um banco real
(**Cloud Firestore**).

- **Servidor publicado:** https://prova-facil-fans.vercel.app
- **Repositório do servidor:** https://github.com/joaopcordeirons/ProvaFacilFANS

## Perfis de acesso

| Perfil | O que faz |
| --- | --- |
| **Professor** | Cria questões e monta provas |
| **Direção** | Revisa e aprova/reprova as provas |
| **Repografia** | Imprime as provas aprovadas |

## Como entrar (modo sem login temporário)

Nesta etapa o login está **desligado**, a pedido do professor: na tela de
login basta escolher o perfil (Professor, Direção ou Repografia) e entrar,
sem e-mail nem senha. Os dados são **reais** (vêm e vão para o Firestore pela
API); só a autenticação foi simplificada.

Como funciona: com `loginAtivo = false` em `lib/config.dart`, o app chama
`POST /api/auth/entrada-direta` com uma chave de teste (`semLoginChave`). O
servidor só aceita essa rota quando está com `SEM_LOGIN=true` e a mesma chave
em `SEM_LOGIN_CHAVE`. Para voltar ao login normal: `loginAtivo = true` no app e
apagar `SEM_LOGIN` no servidor.

## Requisitos da prova × onde estão no app

| Requisito | Como foi atendido |
| --- | --- |
| Multiplataforma (Android e web) | Mesmo código roda nas duas; a sessão usa `Authorization: Bearer` (funciona no navegador) e o download de DOCX tem caminho próprio para web (`lib/arquivos_salvar_web.dart`) |
| Flutter e Dart | Todo o app em Dart |
| Comunicação HTTP | `lib/api.dart` (pacote `http`) fala com a API REST |
| Acesso a banco de dados | API Node/Express + **Cloud Firestore** (nada de dados fixos no código) |
| Persistência | Questões, provas e usuários ficam no Firestore; continuam lá depois de fechar e abrir o app. Também há persistência **local** com `SharedPreferences` (`lib/preferencias.dart`): a opção "Texto grande" (menu lateral) uma **cópia da última lista de questões**, usada quando o servidor ou a internet falham (aparece um aviso de "sem conexão"), o **acesso sem conexão**, sempre sinalizado por uma faixa vermelha "SEM CONEXÃO COM O SERVIDOR" no topo de todas as telas (se o perfil já entrou antes neste aparelho, o app abre o painel com os dados guardados e abre a sessão sozinho quando a internet volta) e o **cadastro de questão sem conexão**: a questão é guardada no aparelho (marcada como "Pendente de envio") e enviada ao servidor automaticamente quando a conexão volta |
| Consulta | Banco de questões e painéis listam dados com `GET /api/questoes` e `GET /api/provas` |
| Cadastro | Nova questão (`POST /api/questoes`), cadastro de conta e montagem/envio de provas |
| Atualização da interface | Depois de cadastrar, editar, excluir ou revisar, as telas recarregam os dados do servidor |
| Validação dos campos | Formulários de questão, cadastro, perfil e login impedem o envio de dados inválidos (`lib/validators.dart`) |
| Tratamento de erros | Falha de conexão, tempo esgotado e erros da API viram mensagens na tela (`ApiException` em `lib/api.dart`) |

## Como executar

Requisitos: Flutter instalado (`flutter doctor` sem erros).

```bash
flutter pub get

# Android (emulador ou celular)
flutter run

# Navegador
flutter run -d chrome
```

Se a pasta `web/` não existir no seu clone, crie com
`flutter create . --platforms=web`.

APK de release:

```bash
flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk
```

### Endereço do servidor

Definido em `lib/config.dart` (`apiBaseUrl`), já apontando para o servidor
publicado, então não é preciso subir nenhum servidor local. Para usar um
servidor local, veja as opções comentadas no próprio arquivo.

No Android, o `AndroidManifest.xml` precisa da permissão de internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Integração com a API

| Tela / botão | Endpoint |
| --- | --- |
| Entrar (acesso direto) | `POST /api/auth/entrada-direta` |
| Entrar (login normal) | `POST /api/auth/login` |
| Cadastre-se | `POST /api/auth/registrar` (+ `GET /api/constantes`) |
| Esqueci minha senha | `POST /api/auth/esqueci-senha` |
| Sair | `POST /api/auth/logout` |
| Perfil: salvar / alterar senha / excluir conta | `PUT /api/auth/perfil`, `POST /api/auth/alterar-senha`, `DELETE /api/auth/conta` |
| Painéis e Banco de Questões | `GET /api/questoes`, `GET /api/provas` |
| Nova questão / editar / excluir | `POST`, `PUT`, `DELETE /api/questoes[/:id]` |
| Salvar rascunho / Enviar para o coordenador | `POST /api/provas/rascunho`, `POST /api/provas/enviar` |
| Gerar PDF / DOCX | `POST /api/provas/gerar-pdf`, `gerar-docx` |
| Excluir rascunho | `DELETE /api/provas/:id` |
| Direção: ver PDF / aprovar / reprovar / em análise | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/revisao` |
| Repografia: abrir PDF / marcar impressão | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/impressao` |

A sessão é um token (JWT) devolvido pelo login, guardado em memória e enviado
em `Authorization: Bearer <token>` em toda requisição.

## Estrutura do projeto

```
lib/
  main.dart                      Ponto de entrada
  theme.dart                     Paleta e tema visual
  models.dart                    Modelos (Usuario, Questao, Prova, Perfil)
  config.dart                    Endereço do servidor e chave do modo sem login
  api.dart                       Cliente HTTP, sessão e tratamento de erros
  app_state.dart                 Sessão e dados compartilhados entre telas
  arquivos.dart                  Abrir/compartilhar PDF e DOCX
  arquivos_salvar_io.dart        Android: folha de compartilhamento
  arquivos_salvar_web.dart       Navegador: download do arquivo
  validators.dart                Validação dos campos
  widgets/                       Menu lateral (por perfil) e componentes comuns
  screens/
    boas_vindas, login, cadastro, recuperar_senha, perfil
    professor/                   Painel, banco de questões, formulário de questão, montagem de prova
    direcao/                     Painel e revisão de provas
    repografia/                  Painel e impressão
```
