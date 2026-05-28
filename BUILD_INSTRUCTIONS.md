# Instruções de Build - Local Viva Flutter

## Problema Resolvido

O build local estava falhando devido a um bug conhecido do Android Gradle Plugin com:
- Java 21 (OpenJDK 21.0.10)
- Gradle 8.x
- Android SDK 34
- Windows

## Solução Implementada

Build automatizado via **GitHub Actions** (CI/CD na nuvem) usando Java 17, que não apresenta o bug do JDK Image Transform.

## Como Gerar o APK para Publicação

### Opção 1: GitHub Actions (Recomendado - Gratuito)

1. **Suba o código para um repositório GitHub**
   ```bash
   git init
   git add .
   git commit -m "Primeiro commit"
   git branch -M main
   git remote add origin https://github.com/SEU_USUARIO/local-viva-app.git
   git push -u origin main
   ```

2. **Dispare o build automaticamente**
   - O workflow está em `.github/workflows/build.yml`
   - O build inicia automaticamente a cada push na branch `main`
   - Ou vá em **Actions** no GitHub e clique em **Run workflow**

3. **Baixe o APK gerado**
   - Vá em **Actions** → último workflow executado
   - Role até **Artifacts** e baixe `release-apk`
   - O arquivo será `app-release.apk`

### Opção 2: Build Web (para PWA)

O workflow também gera uma versão web automaticamente:
- Artifact: `release-web`
- Pode ser hospedado no Firebase Hosting, Netlify, Vercel, etc.

## Configurações Corrigidas

### Android (`android/app/build.gradle`)
- ✅ Java 17 compatível (`VERSION_17`)
- ✅ Signing config com fallback para debug quando não houver keystore
- ✅ ProGuard ativado para release

### Gradle (`android/build.gradle`)
- ✅ Workarounds problemáticos removidos
- ✅ Configuração limpa para CI

### Workflow (`.github/workflows/build.yml`)
- ✅ Java 17 (Temurin)
- ✅ Flutter 3.24.5 (Stable)
- ✅ Build APK + AAB (para Google Play)
- ✅ Build Web
- ✅ Upload automático de artifacts

## Próximos Passos para Publicação

### Google Play Store
1. Gere o **AAB** (Android App Bundle) via GitHub Actions
2. Baixe o artifact `release-aab`
3. Faça upload no Google Play Console

### APK Direto (Instalação manual)
1. Baixe o artifact `release-apk`
2. Distribua o `app-release.apk` diretamente

## Versões do Projeto

| Componente | Versão |
|-----------|--------|
| Flutter | 3.24.5 |
| Dart | 3.5.4 |
| Gradle | 8.5 |
| Android Gradle Plugin | 8.1.0 |
| Kotlin | 1.9.0 |
| Compile SDK | 34 |
| Min SDK | 21 |
| Target SDK | 34 |
| Java | 17 (no CI) |

## Notas Importantes

- O build local continua com o problema do JDK Image Transform no Windows com Java 21
- A solução via CI é definitiva e mais confiável
- O código Flutter está 100% funcional - o problema era apenas ambiental

## Suporte

Se precisar de ajuda com o build, verifique:
1. O GitHub Actions está executando sem erros?
2. Os artifacts foram gerados corretamente?
3. O APK/AAB funciona no emulador/dispositivo?
