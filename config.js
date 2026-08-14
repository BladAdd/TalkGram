/* ═══════════════════════════════════════════════════════════
   TalkGram · конфигурация бэкенда (Supabase)
   ─────────────────────────────────────────────────────────────
   Проект: talkgram (eu-central-1), ref: urnlupdblobqunoqtqsg
   Схема применена: supabase/migrations/0001_init.sql
   Пароль БД хранится в supabase/.db-password (в git не коммитится)
   ═══════════════════════════════════════════════════════════ */
window.SUPABASE_CONFIG = {
  url: 'https://urnlupdblobqunoqtqsg.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVybmx1cGRibG9icXVub3F0cXNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2ODYyMzYsImV4cCI6MjEwMjI2MjIzNn0.d9qqaiwctV_ud16YGeu_5zCXF1VugB7iiW0dMSheN90',

  /* TURN-серверы для звонков между разными сетями (через NAT).
     Пока пусто — звонки работают в пределах одной сети (STUN).
     Бесплатный TURN: https://www.metered.ca/tools/turnserver/ →
     вставить сюда в таком виде:
     { urls: 'turn:relay.metered.ca:80', username: '...', credential: '...' } */
  turnServers: []
};
