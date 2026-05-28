# Problema de Build - JDK Image Transform

## Descrição do Problema

O build do aplicativo está falando com o seguinte erro:

```
Execution failed for task ':flutter_plugin_android_lifecycle:compileDebugJavaWithJavac'.
> Could not resolve all files for configuration ':flutter_plugin_android_lifecycle:androidJdkImage'.
   > Failed to transform core-for-system-modules.jar to match attributes {artifactType=_internal_android_jdk_image, org.gradle.libraryelements=jar, org.gradle.usage=java-runtime}.
      > Execution failed for JdkImageTransform: C:\develop\Android\platforms\android-34\core-for-system-modules.jar.
```

## Causa Raiz

Este é um bug conhecido do Android Gradle Plugin quando usado com:
- Java 21 (OpenJDK Runtime Environment build 21.0.10)
- Android SDK 34
- Gradle 8.x
- Windows

O problema ocorre durante a transformação do arquivo `core-for-system-modules.jar` usando `jlink.exe`.

## Tentativas de Correção

Foram testadas as seguintes soluções sem sucesso:

1. ✗ Downgrade do Gradle (7.4, 7.5, 8.0, 8.3, 8.5, 8.9)
2. ✗ Downgrade do Android Gradle Plugin (7.3.1, 7.4.2, 8.1.0, 8.7.3)
3. ✗ Downgrade do Kotlin (1.7.10, 1.9.0)
4. ✗ Downgrade do Android SDK (33)
5. ✗ Propriedades do gradle.properties:
   - `android.disableAutomaticComponentCreation=true` (removida no AGP 8.0)
   - `org.gradle.unsafe.configuration-cache=false`
   - `org.gradle.caching=false`
   - `android.experimental.enableSourceSetPathsMap=false`
6. ✗ Configurações no build.gradle para desabilitar transforms

## Soluções Alternativas

### Opção 1: Usar Codemagic (Recomendado)

Codemagic é um serviço de CI/CD gratuito para Flutter que não tem esse problema:

1. Criar conta em https://codemagic.io
2. Conectar o repositório Git
3. Configurar o workflow de build
4. O APK será gerado automaticamente na nuvem

### Opção 2: Usar GitHub Actions

Criar arquivo `.github/workflows/build.yml`:

```yaml
name: Build APK
on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.5'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### Opção 3: Usar Docker Localmente

```bash
docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable flutter build apk --release
```

### Opção 4: Instalar Java 17 Localmente

1. Baixar Java 17 de https://adoptium.net/
2. Configurar JAVA_HOME para apontar para Java 17
3. Executar `flutter build apk`

## Configuração Atual do Projeto

- Flutter: 3.24.5
- Dart: 3.5.4
- Android Gradle Plugin: 8.7.3
- Gradle: 8.9
- Kotlin: 1.9.0
- Java: OpenJDK 21.0.10
- Android SDK: 34
- Min SDK: 21
- Target SDK: 34

## Próximos Passos Recomendados

1. **Usar Codemagic ou GitHub Actions** para gerar o APK na nuvem
2. **OU** Instalar Java 17 localmente e configurar o projeto para usá-lo
3. Após gerar o APK, testá-lo no emulador ou dispositivo físico
