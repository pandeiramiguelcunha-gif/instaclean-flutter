# 🚀 Guia de Configuração: Firebase, AdMob e Play Store

## 1️⃣ FIREBASE - Configuração

### Passo 1: Criar projeto no Firebase
1. Vai a: https://console.firebase.google.com
2. Clica em **"Adicionar projeto"**
3. Nome do projeto: `InstaClean-PMC`
4. Desativa Google Analytics (opcional)
5. Clica em **"Criar projeto"**

### Passo 2: Adicionar app Android
1. No painel do Firebase, clica no ícone **Android**
2. Preenche:
   - **Nome do pacote Android**: `com.instaclean.app`
   - **Apelido da app**: `Instaclean PMC`
   - **Certificado SHA-1**: (obter do Codemagic ou Android Studio)
3. Clica em **"Registar app"**

### Passo 3: Descarregar google-services.json
1. Clica em **"Transferir google-services.json"**
2. Coloca o ficheiro em: `/android/app/google-services.json`
3. Faz commit para o GitHub

---

## 2️⃣ ADMOB - Monetização

### Passo 1: Criar conta AdMob
1. Vai a: https://admob.google.com
2. Cria ou faz login na conta

### Passo 2: Registar a app
1. Clica em **"Apps"** → **"Adicionar app"**
2. Seleciona **Android**
3. Nome: `Instaclean - Limpeza Inteligente`
4. Copia o **App ID** (formato: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

### Passo 3: Criar unidades de anúncio
1. **Banner**: Apps → Instaclean → Unidades de anúncio → Criar → Banner
2. **Intersticial**: Apps → Instaclean → Unidades de anúncio → Criar → Intersticial

### Passo 4: Atualizar o código
Substitui os IDs nos ficheiros:

**AndroidManifest.xml** (linha 20):
```xml
android:value="ca-app-pub-SEU_APP_ID_AQUI"/>
```

**lib/services/ad_service.dart** (linhas 17-18):
```dart
static const String _prodBannerAdUnitId = 'ca-app-pub-SEU_BANNER_ID';
static const String _prodInterstitialAdUnitId = 'ca-app-pub-SEU_INTERSTICIAL_ID';
```

**IMPORTANTE**: Muda `_useTestAds = false` quando publicares!

---

## 3️⃣ ASSINATURA DIGITAL - Keystore

### Opção A: Codemagic gera automaticamente
1. No Codemagic, vai a **Settings** → **Code signing**
2. Ativa **"Automatic code signing"**
3. O Codemagic gera e guarda a keystore

### Opção B: Criar manualmente
```bash
keytool -genkey -v -keystore instaclean-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias instaclean
```

### Configurar no Codemagic:
1. Vai a **Settings** → **Environment variables**
2. Adiciona grupo `keystore_credentials`:
   - `CM_KEYSTORE`: (base64 do ficheiro .jks)
   - `CM_KEYSTORE_PASSWORD`: (password da store)
   - `CM_KEY_PASSWORD`: (password da key)
   - `CM_KEY_ALIAS`: `instaclean`

---

## 4️⃣ GOOGLE PLAY CONSOLE

### Passo 1: Criar conta de desenvolvedor
1. Vai a: https://play.google.com/console
2. Paga a taxa de $25 (uma vez)
3. Preenche os dados da conta

### Passo 2: Criar app
1. Clica em **"Criar app"**
2. Nome: `Instaclean - Limpeza Inteligente`
3. Idioma: Português
4. Tipo: App
5. Gratuita

### Passo 3: Preencher detalhes da loja
- **Descrição curta**: Limpe ficheiros duplicados e liberte espaço!
- **Descrição completa**: (texto detalhado sobre a app)
- **Ícone**: 512x512 PNG
- **Screenshots**: Mínimo 2 screenshots
- **Gráfico de funcionalidades**: 1024x500 PNG

### Passo 4: Upload do AAB
1. Vai a **Produção** → **Criar nova versão**
2. Faz upload do ficheiro `.aab` do Codemagic
3. Adiciona notas da versão
4. Envia para revisão

---

## 5️⃣ CODEMAGIC - Build de Release

### Configurar variáveis de ambiente:
No Codemagic → Settings → Environment variables:

```
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS = (JSON da conta de serviço Google Play)
```

### Iniciar build:
1. Faz push do código para GitHub
2. No Codemagic, seleciona **"release-workflow"**
3. Clica em **"Start new build"**
4. Aguarda o AAB ser gerado

---

## ✅ CHECKLIST FINAL

- [ ] Projeto Firebase criado
- [ ] google-services.json no GitHub
- [ ] App ID do AdMob configurado
- [ ] Banner Ad Unit ID configurado
- [ ] Interstitial Ad Unit ID configurado
- [ ] `_useTestAds = false` no ad_service.dart
- [ ] Keystore configurada no Codemagic
- [ ] Conta Google Play criada
- [ ] App criada no Play Console
- [ ] Build AAB gerado com sucesso
- [ ] AAB enviado para o Play Console

---

## 📞 SUPORTE

Se tiveres problemas:
1. Verifica os logs do Codemagic
2. Confirma que todos os IDs estão corretos
3. Testa primeiro com IDs de teste antes de publicar
