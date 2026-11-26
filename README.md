# InTimeOS Mobile — In Time Technology

Aplicativo móvel oficial para os colaboradores da **In Time Technology**, integrado à API v5 do **InTimeOS** (`https://itos.intimelab.com.br`).

## Destaques e Funcionalidades 🛠️

- **Identidade Visual In Time Technology:** Paleta oficial (`#14172F`, `#0F1225`, `#0284C7` e `#38BDF8`), logos e fundo personalizados do InTimeOS.
- **Conexão Pré-configurada:** Servidor padrão `https://itos.intimelab.com.br` configurado automaticamente no primeiro acesso (com suporte também a servidores em rede local / laboratório na porta `18080`).
- **Autenticação Segura (API v5) + Cloudflare Access (Zero Trust):**
  - Suporte nativo a **Service Token do Cloudflare Access** (`CF-Access-Client-Id` e `CF-Access-Client-Secret`), permitindo que o aplicativo atravesse a página de validação por e-mail do Cloudflare Zero Trust sem bloquear as requisições JSON da API.
  - Detecção automática de bloqueio do Cloudflare Access (`/cdn-cgi/access/login`) no teste de conexão e no login, abrindo a configuração do Service Token.
  - Suporte completo a **Autenticação em Dois Fatores (2FA / TOTP)** e códigos de recuperação no login.
  - Renovação automática de sessão com **Refresh Token** de uso único (`POST /api/v1/refresh`).
  - Revogação de sessão no servidor ao sair (`POST /api/v1/logout`).
- **Painel Técnico para Colaboradores:**
  - KPIs operacionais no topo: **Em andamento**, **Aguardando peças**, **Orçamentos** e **Finalizadas**, com filtro rápido ao tocar.
  - Fila técnica de OS com alternador rápido entre **Andamento**, **Abertas** e **Peças**.
  - Busca rápida de OS pelo número (`#ID`) e alertas de **Estoque baixo**.
- **Gestão Completa de Ordens de Serviço (OS):**
  - Auto-seleção do técnico logado ao abrir uma nova OS (funciona mesmo para perfis técnicos sem permissão `cUsuario`).
  - Preenchimento de **Laudo Técnico** e **Garantia** tanto na criação quanto na edição.
  - Chips de ação rápida no cabeçalho da OS para avançar status com um toque (`Em Andamento`, `Aguardando Peças`, `Orçamento`, `Aprovado`, `Finalizado`).
  - Atalho para **Impressão de OS em 2 vias (A4)** e envio de resumo completo por **WhatsApp**.
  - Adição/edição de produtos, serviços, descontos (`tipoDesconto` / `tipo_desconto`), anotações técnicas e upload/visualização de fotos e anexos autenticados.
- **Clientes, Produtos, Serviços e Agenda:**
  - Cadastro e consulta de clientes com busca automática de CEP (ViaCEP), histórico de OS, ligação e WhatsApp.
  - Controle de estoque de produtos e catálogo de serviços.
  - Agenda de entregas integrada ao calendário do InTimeOS.
- **Perfil do Colaborador:**
  - Edição dos próprios dados cadastrais e **troca de senha** diretamente pelo aplicativo (`PUT /api/v1/usuarios/{id}`).

## Ambiente de Desenvolvimento 💻

Para executar ou compilar o projeto localmente, é necessário ter o **Flutter SDK (^3.7.2)** instalado.

1. Entre na pasta do aplicativo:
   ```bash
   cd InTimeOS_app/map-os-app-flutter
   ```

2. Baixe as dependências:
   ```bash
   flutter pub get
   ```

3. Execute os testes:
   ```bash
   flutter test
   ```

4. Gere o APK de produção:
   ```bash
   flutter build apk --release
   ```

   > **Dica (Cloudflare Access embutido no APK):** Você pode embutir o Service Token do Cloudflare Access diretamente na build do APK para que os funcionários não precisem digitá-lo manualmente:
   > ```bash
   > flutter build apk --release \
   >   --dart-define=CF_ACCESS_CLIENT_ID=seu_client_id.access \
   >   --dart-define=CF_ACCESS_CLIENT_SECRET=seu_client_secret
   > ```

## Como configurar no painel Cloudflare Zero Trust 🛡️

Como o domínio `itos.intimelab.com.br` está protegido pela validação por e-mail do Cloudflare Access:

1. No painel **Cloudflare Zero Trust**, acesse **Access → Service Auth → Service Tokens** e clique em **Create Service Token**.
2. Copie o **`CF-Access-Client-Id`** e o **`CF-Access-Client-Secret`** gerados.
3. Vá em **Access → Applications**, edite a aplicação do **InTimeOS** e adicione uma nova política (**Add a policy**):
   - **Policy name:** `InTimeOS Mobile App`
   - **Action:** **`Service Auth`** (importante: deve ser `Service Auth`, não `Allow`)
   - **Include → Selector:** `Service Token` → selecione o token criado.
4. No aplicativo (ou via `--dart-define` na compilação do APK), ative **Proteção Cloudflare Access** na configuração do servidor e informe o Client ID e o Client Secret.


