// ═══════════════════════════════════════════════════════════
// ODARA ACADEMY — SHARED CORE
// Cliente Supabase, auth e utilitários usados pelos 3 painéis
// ═══════════════════════════════════════════════════════════

const SUPABASE_URL  = 'https://khqbimmcibutfrfmkoxr.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocWJpbW1jaWJ1dGZyZm1rb3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNTY1NjUsImV4cCI6MjA4OTkzMjU2NX0.w3vRAPhiU7Zavgkiv-ldjbHc_UJeGH9ck2tq_YN6MBo';

window.ODARA = window.ODARA || {};
window.ODARA.sb = null;
window.ODARA.ME = null;

// ── Espera o SDK do Supabase carregar (até 8s)
window.ODARA.waitForSupabase = function(timeout = 8000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    (function check() {
      if (window.supabase && typeof window.supabase.createClient === 'function') return resolve();
      if (Date.now() - start > timeout) return reject(new Error('Supabase SDK não carregou'));
      setTimeout(check, 100);
    })();
  });
};

window.ODARA.initSupabase = async function() {
  await window.ODARA.waitForSupabase();
  window.ODARA.sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  return window.ODARA.sb;
};

// ── Login / auth
window.ODARA.signIn = async function(email, password) {
  const { data, error } = await window.ODARA.sb.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
};

window.ODARA.signOut = async function() {
  await window.ODARA.sb.auth.signOut();
  window.ODARA.ME = null;
};

window.ODARA.sendMagicLink = async function(email) {
  const { error } = await window.ODARA.sb.auth.signInWithOtp({ email });
  if (error) throw error;
};

window.ODARA.loadMe = async function() {
  const { data: { session } } = await window.ODARA.sb.auth.getSession();
  if (!session) return null;
  const { data, error } = await window.ODARA.sb.from('profiles').select('*').eq('id', session.user.id).single();
  if (error || !data) {
    console.error('loadMe:', error);
    return null;
  }
  window.ODARA.ME = data;
  return data;
};

// ── Checa permissão de role
window.ODARA.requireRole = function(allowed) {
  const me = window.ODARA.ME;
  if (!me) return false;
  return allowed.includes(me.role);
};

// ── Utils
window.ODARA.toast = function(icon, title, msg = '') {
  let t = document.getElementById('od-toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'od-toast';
    t.className = 'toast';
    t.innerHTML = '<span class="ti"></span><span><span class="tt"></span> <span class="tm"></span></span>';
    document.body.appendChild(t);
  }
  t.querySelector('.ti').textContent = icon;
  t.querySelector('.tt').textContent = title;
  t.querySelector('.tm').textContent = msg;
  t.classList.add('show');
  clearTimeout(window.ODARA._toastTimer);
  window.ODARA._toastTimer = setTimeout(() => t.classList.remove('show'), 2800);
};

window.ODARA.getInitials = function(name) {
  if (!name) return '?';
  return name.trim().split(/\s+/).slice(0, 2).map(n => n[0]).join('').toUpperCase();
};

window.ODARA.greeting = function() {
  const h = new Date().getHours();
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
};

window.ODARA.fmtDate = function(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleDateString('pt-BR');
};

window.ODARA.fmtDateTime = function(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
};

window.ODARA.daysAgo = function(iso) {
  if (!iso) return 0;
  return Math.floor((Date.now() - new Date(iso).getTime()) / 86400000);
};

window.ODARA.ytExtract = function(url) {
  if (!url) return null;
  const m = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|v\/)|youtu\.be\/)([^&?\s/]+)/);
  return m ? m[1] : null;
};

window.ODARA.NIVEL_LABEL = {
  0: 'Não conhece',
  1: 'Conhece',
  2: 'Aplica',
  3: 'Aplica com autonomia',
  4: 'Ensina'
};

window.ODARA.NIVEL_SHORT = { 0: 'N/C', 1: 'Conhece', 2: 'Aplica', 3: 'Autonomia', 4: 'Ensina' };

// ── Render de login (usado por gestor e admin)
window.ODARA.renderLogin = function(container, opts = {}) {
  const { title = 'Odara · Academy', subtitle = 'Acesso restrito.', onSuccess } = opts;
  container.innerHTML = `
    <div class="login">
      <div class="login-top">
        <div class="login-brand">${title}</div>
        <h1 class="login-title">Bem-vindo<br>de volta.</h1>
        <p class="login-sub">${subtitle}</p>
      </div>
      <div class="login-card">
        <label class="label">E-mail</label>
        <input id="od-login-email" class="input" type="email" placeholder="seu@email.com" autocomplete="email">
        <div style="margin-top:14px"></div>
        <label class="label">Senha</label>
        <input id="od-login-pass" class="input" type="password" placeholder="••••••••" autocomplete="current-password">
        <button class="btn btn-dark btn-lg" id="od-login-btn" style="width:100%;margin-top:18px">Entrar</button>
        <p class="login-help">Sem senha? <a id="od-magic">Receber link por e-mail</a></p>
      </div>
    </div>`;

  const emailEl = document.getElementById('od-login-email');
  const passEl = document.getElementById('od-login-pass');
  passEl.addEventListener('keydown', e => { if (e.key === 'Enter') doLogin(); });

  async function doLogin() {
    const email = emailEl.value.trim();
    const pass = passEl.value;
    if (!email || !pass) { window.ODARA.toast('⚠', 'Campos', 'Preencha e-mail e senha'); return; }
    try {
      await window.ODARA.signIn(email, pass);
      await window.ODARA.loadMe();
      if (onSuccess) onSuccess(window.ODARA.ME);
    } catch (e) {
      window.ODARA.toast('⚠', 'Erro', e.message || 'Falha no login');
    }
  }

  document.getElementById('od-login-btn').addEventListener('click', doLogin);
  document.getElementById('od-magic').addEventListener('click', async () => {
    const email = emailEl.value.trim();
    if (!email) { window.ODARA.toast('⚠', 'E-mail', 'Informe seu e-mail'); return; }
    try {
      await window.ODARA.sendMagicLink(email);
      window.ODARA.toast('✉', 'Link enviado', 'Verifique seu e-mail');
    } catch (e) {
      window.ODARA.toast('⚠', 'Erro', e.message);
    }
  });
};

// ── Render de erro "sem permissão" (para gestor/admin)
window.ODARA.renderForbidden = function(container, requiredRoles) {
  container.innerHTML = `
    <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:40px 20px">
      <div style="max-width:360px;text-align:center">
        <div style="font-size:56px;margin-bottom:18px">🔒</div>
        <div class="font-display" style="font-size:26px;font-weight:700;margin-bottom:8px">Acesso restrito</div>
        <div style="color:var(--od-gray);font-size:14px;margin-bottom:20px">
          Esta área é exclusiva para ${requiredRoles.join(' ou ')}.
          Seu perfil atual (${window.ODARA.ME?.role || 'colaborador'}) não tem permissão.
        </div>
        <a href="index.html" class="btn btn-primary" style="text-decoration:none">Voltar para o app</a>
        <div style="margin-top:12px">
          <a onclick="ODARA.signOut().then(()=>location.reload())" style="color:var(--od-red);font-size:12px;cursor:pointer">Sair e entrar com outra conta</a>
        </div>
      </div>
    </div>`;
};
