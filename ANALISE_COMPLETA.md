# 📊 ANÁLISE COMPLETA DO APLICATIVO LOCAL VIVA

## 🎯 Visão Geral

**Local Viva** é um aplicativo de marketplace local para compra e venda de produtos/serviços, desenvolvido em Flutter. O aplicativo permite que usuários anunciem itens, busquem produtos favoritos, enviem mensagens e interajam com outros usuários da mesma região.

---

## 🏗️ Arquitetura e Estrutura

### **Tecnologia Principal**
- **Flutter** (Dart) - Framework cross-platform
- **Provider** - State management
- **HTTP/Dio** - Requisições de rede
- **SharedPreferences** - Armazenamento local
- **WebView** - Integração com conteúdo web
- **Image Picker** - Captura de fotos
- **Geolocator** - Serviços de localização

### **Estrutura de Pastas**
```
lib/
├── config/          # Configurações (API, constantes)
├── models/          # Models de dados (Ad, User, Message, etc.)
├── providers/       # State management (Auth, Ads, Favorites, Messages)
├── screens/         # Telas do aplicativo
│   ├── ads/         # Anúncios
│   ├── auth/        # Autenticação
│   ├── favorites/   # Favoritos
│   ├── home/        # Tela principal
│   ├── messages/    # Mensagens
│   └── profile/     # Perfil do usuário
├── services/        # Serviços (API, Banner, Boost)
├── utils/           # Utilitários (storage, theme, etc.)
└── widgets/         # Componentes reutilizáveis
```

---

## 📱 Funcionalidades Principais

### **1. Autenticação**
- **Login/Registro** com email, senha e telefone
- **Gerenciamento de sessão** com token JWT
- **Recuperação de dados do usuário** via API
- **Logout** com limpeza de dados locais

### **2. Anúncios**
- **Criação de anúncios** com múltiplas fotos
- **Busca e filtros** (categoria, preço, localização, condição)
- **Listagem infinita** com scroll
- **Detalhes do anúncio** com informações completas
- **Edição e exclusão** de anúncios próprios
- **Sistema de boost** (destaque pago via PayPal)

### **3. Interação Social**
- **Sistema de favoritos** para salvar anúncios
- **Mensagens privadas** entre usuários
- **Contato direto** com vendedores
- **Notificações** de mensagens não lidas

### **4. Localização**
- **Geolocalização** para anúncios próximos
- **Filtros por cidade/estado**
- **Busca por localização**

### **5. Pagamentos**
- **Integração PayPal** para boost de anúncios
- **Planos de destaque** (super destaque, turbo, normal)

---

## 🔗 API e Backend

### **URL Base**: `https://localviva.com.br/api`

### **Endpoints Principais**:
- `/auth/login` - Autenticação
- `/auth/register` - Registro
- `/auth/me` - Dados do usuário
- `/ads` - CRUD de anúncios
- `/categories` - Categorias
- `/favorites` - Favoritos
- `/messages` - Mensagens
- `/boost` - Boost de anúncios
- `/paypal_boost` - Pagamentos PayPal

### **Upload de Imagens**: `https://localviva.com.br/uploads`
### **Proxy de Imagens**: `https://localviva.com.br/api/proxy_image.php`

---

## 📊 Models de Dados

### **AdModel** (Anúncio)
- id, title, description, price, negotiable
- conditionType, city, state, categoryName
- images, sellerName, sellerPhone
- views, createdAt, isFavorited
- boostType, boostExpiresAt, status
- Localização (cep, neighborhood, address)

### **UserModel** (Usuário)
- id, name, email, phone
- Dados de autenticação e perfil

### **MessageModel** (Mensagem)
- id, conversation_id, sender_id, receiver_id
- content, created_at, read_at

### **ConversationModel** (Conversa)
- id, ad_id, ad_title, other_user_name
- last_message, unread_count

---

## 🔄 Fluxo do Aplicativo

### **1. Splash Screen**
- Verificação de autenticação
- Carregamento inicial

### **2. Home Screen**
- Feed de anúncios com scroll infinito
- Barra de busca
- Filtros avançados
- Categorias em destaque
- Banners promocionais

### **3. Navegação**
- **Drawer lateral** com menu principal
- **Navegação por tabs** para diferentes seções
- **Deep linking** para detalhes de anúncios

### **4. Fluxo de Autenticação**
- Login → Home (se autenticado)
- Login → Home (se não autenticado, com prompt)

---

## 🎨 UI/UX Design

### **Cores e Tema**
- Gradiente principal (hero gradient)
- Cores primárias/secundárias definidas
- Material Design 3

### **Componentes**
- **AdCard** - Cards de anúncios
- **BannerWidget** - Banners promocionais
- **CategoryCard** - Cards de categorias
- **BrandLogo** - Logo da marca

### **Layout**
- **AppBar** com logo e notificações
- **Drawer** para navegação principal
- **Bottom sheets** para filtros e ações
- **Refresh indicators** para atualização

---

## 💾 Armazenamento Local

### **SharedPreferences**
- Token de autenticação
- Dados do usuário (cache)
- Preferências do aplicativo

### **StorageHelper**
- Métodos para salvar/recuperar tokens
- Verificação de status de login
- Limpeza de dados

---

## 🔧 Serviços e Utilitários

### **ApiService**
- Requisições HTTP com autenticação
- Tratamento de erros
- Debug logging extensivo

### **BannerService**
- Carregamento de banners promocionais
- Cache de banners

### **BoostService**
- Gerenciamento de boost de anúncios
- Integração com PayPal

---

## 📱 Screens Principais

### **1. HomeScreen** (Principal)
- Feed de anúncios
- Busca e filtros
- Categorias
- Banners

### **2. AdDetailScreen** (Detalhes)
- Informações completas do anúncio
- Galeria de imagens
- Contato com vendedor
- Botões de favorito/mensagem

### **3. CreateAdScreen** (Criar Anúncio)
- Formulário completo
- Upload de múltiplas fotos
- Validação de dados

### **4. MessagesScreen** (Mensagens)
- Lista de conversas
- Contador de não lidas
- Navegação para chat

### **5. ProfileScreen** (Perfil)
- Dados do usuário
- Links para funcionalidades
- Logout

---

## 🛡️ Segurança

### **Autenticação**
- Token JWT armazenado localmente
- Headers de autorização em requisições
- Verificação de token expirado

### **Validações**
- Validação de formulários
- Sanitização de inputs
- Tratamento de erros

---

## 🚀 Performance

### **Otimizações**
- **Cached Network Image** para imagens
- **Lazy loading** de conteúdo
- **Infinite scroll** com paginação
- **Refresh indicators** para UX

### **Cache**
- Imagens com cache
- Dados de usuário em cache
- Banners em cache

---

## 🔄 Estado Global (Providers)

### **AuthProvider**
- Gerenciamento de sessão
- Login/logout
- Dados do usuário

### **AdsProvider**
- Lista de anúncios
- Filtros e busca
- Paginação

### **FavoritesProvider**
- Lista de favoritos
- Adicionar/remover favoritos

### **MessagesProvider**
- Conversas e mensagens
- Contadores de não lidas

---

## 🌐 Integrações Externas

### **PayPal**
- Pagamentos para boost de anúncios
- WebView para checkout

### **WebView**
- Conteúdo web integrado
- Navegação segura

### **Geolocator**
- GPS para localização
- Permissões de localização

---

## 📋 Fluxo de Usuário Típico

1. **Abrir app** → Splash → Verificação de auth
2. **Home** → Scroll de anúncios → Buscar/filtrar
3. **Ver anúncio** → Detalhes → Favoritar/mensagem
4. **Login** (se necessário) → Acessar funcionalidades
5. **Criar anúncio** → Formulário → Upload fotos
6. **Mensagens** → Chat com outros usuários
7. **Perfil** → Gerenciar conta/anúncios

---

## 🔍 Pontos Importantes

### **API Centralizada**
- Todas as requisições passam por ApiService
- Tratamento unificado de erros
- Logging extensivo para debug

### **State Management**
- Provider pattern para estado global
- Rebuilds otimizados
- Separação clara de responsabilidades

### **Navegação**
- Drawer principal para navegação
- Deep linking para anúncios
- Auth guards para telas protegidas

### **UX Considerations**
- Loading states em todas as operações
- Tratamento de erros amigável
- Offline support básico

---

## 🎯 Conclusão

O **Local Viva** é um marketplace local bem estruturado com:
- **Arquitetura limpa** e organizada
- **State management** eficiente
- **API integration** robusta
- **UX/UX** pensada para o usuário final
- **Funcionalidades completas** de marketplace

O código segue boas práticas de desenvolvimento Flutter, com separação clara de responsabilidades e componentes reutilizáveis.
