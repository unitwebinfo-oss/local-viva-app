# Local Viva - Aplicativo Mobile

Aplicativo oficial do Local Viva para Android e iOS.

## 🚀 Tecnologias

- Flutter 3.0+
- Dart 3.0+
- Provider (State Management)
- HTTP/Dio (Network)
- Cached Network Image
- Shared Preferences

## 📋 Pré-requisitos

- Flutter SDK instalado ([Guia de instalação](https://docs.flutter.dev/get-started/install))
- Android Studio (para Android) ou Xcode (para iOS)
- Dispositivo físico ou emulador configurado

## 🔧 Configuração

### 1. Instalar dependências

```bash
cd Aplicativo
flutter pub get
```

### 2. Configurar API

O aplicativo está configurado para usar a API em:
- **Produção**: `https://localviva.com.br/api`
- **Uploads**: `https://localviva.com.br/uploads`

Para alterar, edite o arquivo `lib/config/api_config.dart`.

### 3. Executar em modo desenvolvimento

```bash
# Android
flutter run

# iOS (apenas macOS)
flutter run -d ios

# Web (para testes)
flutter run -d chrome
```

## 📱 Build para Produção

### Android (APK)

```bash
flutter build apk --release
```

O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle - Google Play)

```bash
flutter build appbundle --release
```

O bundle será gerado em: `build/app/outputs/bundle/release/app-release.aab`

### iOS (apenas macOS)

```bash
flutter build ios --release
```

Depois abra o Xcode para fazer o upload para a App Store.

## 🔑 Configuração de Assinatura

### Android

1. Crie um keystore:
```bash
keytool -genkey -v -keystore local-viva-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias local-viva
```

2. Crie o arquivo `android/key.properties`:
```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=local-viva
storeFile=../local-viva-key.jks
```

3. O arquivo `android/app/build.gradle` já está configurado para usar essas chaves.

### iOS

1. Configure no Xcode:
   - Abra `ios/Runner.xcworkspace`
   - Selecione o projeto Runner
   - Em "Signing & Capabilities", configure seu Team e Bundle Identifier

## 📦 Estrutura do Projeto

```
lib/
├── config/          # Configurações (API, constantes)
├── models/          # Modelos de dados
├── providers/       # State management (Provider)
├── screens/         # Telas do app
│   ├── auth/        # Login, registro
│   ├── home/        # Tela inicial
│   └── ads/         # Detalhes de anúncios
├── services/        # Serviços (API)
├── utils/           # Utilitários (theme, storage)
├── widgets/         # Componentes reutilizáveis
└── main.dart        # Entry point
```

## 🌐 API Endpoints

O app consome os seguintes endpoints da API REST:

- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro
- `GET /api/auth/me` - Dados do usuário
- `GET /api/ads` - Listar anúncios
- `GET /api/ads/{id}` - Detalhes do anúncio
- `GET /api/categories` - Categorias
- `GET /api/favorites` - Favoritos do usuário
- `POST /api/favorites` - Adicionar favorito
- `DELETE /api/favorites/{id}` - Remover favorito
- `GET /api/messages/conversations` - Conversas
- `POST /api/messages` - Enviar mensagem

## 🎨 Personalização

### Cores

Edite `lib/utils/theme.dart` para alterar as cores do app:

```dart
static const Color primary = Color(0xFF0d9488);  // Verde principal
static const Color accent = Color(0xFFf97316);   // Laranja
```

### Nome e Ícone

- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/Info.plist`

## 📝 Publicação nas Lojas

### Google Play Store

1. Crie uma conta de desenvolvedor no [Google Play Console](https://play.google.com/console)
2. Gere o App Bundle: `flutter build appbundle --release`
3. Faça upload do arquivo `.aab` no Play Console
4. Preencha as informações do app (descrição, screenshots, etc.)
5. Envie para revisão

### Apple App Store

1. Crie uma conta de desenvolvedor Apple
2. Configure o app no [App Store Connect](https://appstoreconnect.apple.com)
3. Build: `flutter build ios --release`
4. Abra o Xcode e faça upload via "Product > Archive"
5. Envie para revisão no App Store Connect

## 🐛 Troubleshooting

### Erro de certificado SSL
Se tiver problemas com certificados SSL em desenvolvimento, adicione exceções temporárias (apenas dev).

### Problemas com dependências
```bash
flutter clean
flutter pub get
```

### Erro de build Android
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

## 📞 Suporte

Para dúvidas ou problemas, entre em contato através do site Local Viva.

## 📄 Licença

© 2026 Local Viva. Todos os direitos reservados.
