/* ═══════════════════════════════════════════════════════════
   TalkGram · конфигурация бэкенда (Supabase)
   ─────────────────────────────────────────────────────────────
   ШАГ 1. Создайте бесплатный проект: https://supabase.com → New project
   ШАГ 2. Project Settings → API → скопируйте "Project URL" и "anon public" key
   ШАГ 3. Вставьте их ниже (между кавычками) и сохраните файл
   ШАГ 4. В Supabase Dashboard → SQL Editor выполните весь файл
          supabase/schema.sql (создаст таблицы, RLS и realtime)
   ШАГ 5. Authentication → Providers → Email:
          для мгновенного входа без письма отключите "Confirm email"
          (для продакшена подтверждение лучше оставить включённым)
   ═══════════════════════════════════════════════════════════ */
window.SUPABASE_CONFIG = {
  url: '',     // пример: 'https://abcdefghijkl.supabase.co'
  anonKey: '', // пример: 'eyJhbGciOiJIUzI1NiIs...' (публичный anon-ключ)

  /* TURN-серверы для звонков между разными сетями (через NAT).
     Пока пусто — звонки работают в пределах одной сети (STUN).
     Бесплатный TURN: https://www.metered.ca/tools/turnserver/ →
     вставить сюда в таком виде:
     { urls: 'turn:relay.metered.ca:80', username: '...', credential: '...' } */
  turnServers: []
};
