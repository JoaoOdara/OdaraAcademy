# PATCH PARA `academy-gestao.html`

Como o seu `academy-gestao.html` já existe e tem muito código, o jeito mais seguro é **adicionar** os trechos abaixo nos lugares indicados, sem reescrever o arquivo todo.

---

## 1. Adicione um item de menu/aba de curadoria

Procure no seu `academy-gestao.html` o trecho onde você define as abas (algo como `data-tab="trilhas"` ou `setTab('trilhas')`). Adicione ao lado:

```html
<button onclick="setTab('curadoria')" data-tab="curadoria">★ Curadoria</button>
```

---

## 2. Adicione a tela da aba (cole junto das outras telas/divs de tab)

```html
<div id="tab-curadoria" class="tab-content" style="display:none">
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
    <h2 style="font-family:'Barlow Condensed',sans-serif;font-size:24px;font-weight:700;color:#0C0C0C">Curadoria externa</h2>
    <button onclick="abrirFormCuradoria()" style="background:#FFB81D;color:#0C0C0C;border:none;padding:10px 16px;border-radius:8px;font-weight:700;cursor:pointer">+ Novo item</button>
  </div>
  <div id="lista-curadoria" style="display:flex;flex-direction:column;gap:8px"></div>
</div>

<!-- modal de formulário -->
<div id="modal-cur" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:200;align-items:center;justify-content:center">
  <div style="background:#fff;width:90%;max-width:480px;max-height:90vh;overflow-y:auto;border-radius:16px;padding:24px">
    <h3 id="cur-form-title" style="font-family:'Barlow Condensed',sans-serif;font-size:22px;margin-bottom:16px">Novo item de curadoria</h3>
    <input type="hidden" id="cur-id">
    <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Título *</label>
    <input id="cur-titulo" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
    <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Descrição</label>
    <textarea id="cur-desc" rows="2" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px;resize:vertical"></textarea>
    <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">URL (link) *</label>
    <input id="cur-url" placeholder="https://..." style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
    <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Fonte</label>
    <input id="cur-fonte" placeholder="Ex: SENAI, SEBRAE, YouTube" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
      <div>
        <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Área *</label>
        <select id="cur-area" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
          <option>Qualidade</option>
          <option>Produção</option>
          <option>Liderança</option>
          <option>Segurança</option>
          <option>Manutenção</option>
          <option>Geral</option>
        </select>
      </div>
      <div>
        <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Formato *</label>
        <select id="cur-formato" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
          <option value="video">Vídeo</option>
          <option value="curso">Curso</option>
          <option value="artigo">Artigo</option>
          <option value="podcast">Podcast</option>
          <option value="ebook">E-book / PDF</option>
          <option value="planilha">Planilha</option>
        </select>
      </div>
      <div>
        <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Duração (min)</label>
        <input id="cur-dur" type="number" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
      </div>
      <div>
        <label style="font-size:11px;font-weight:700;text-transform:uppercase;color:#666">Nível</label>
        <select id="cur-nivel" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;margin:4px 0 12px">
          <option value="todos">Todos</option>
          <option value="iniciante">Iniciante</option>
          <option value="intermediario">Intermediário</option>
          <option value="avancado">Avançado</option>
        </select>
      </div>
    </div>
    <label style="display:flex;align-items:center;gap:8px;margin:8px 0">
      <input type="checkbox" id="cur-destaque"> <span>Marcar como destaque (★)</span>
    </label>
    <div style="display:flex;gap:8px;margin-top:16px">
      <button onclick="document.getElementById('modal-cur').style.display='none'" style="flex:1;padding:12px;background:#eee;border:none;border-radius:8px;font-weight:600;cursor:pointer">Cancelar</button>
      <button onclick="salvarCuradoria()" style="flex:1;padding:12px;background:#0C0C0C;color:#FFB81D;border:none;border-radius:8px;font-weight:700;cursor:pointer">Salvar</button>
    </div>
  </div>
</div>
```

---

## 3. Adicione as funções JS (no `<script>` da página)

```javascript
// CURADORIA — listar
async function carregarCuradoria() {
  const { data, error } = await sb.from('curadoria_externa')
    .select('*').order('destaque',{ascending:false}).order('created_at',{ascending:false});
  const lista = document.getElementById('lista-curadoria');
  if (error) { lista.innerHTML = `<p style="color:#c00">${error.message}</p>`; return; }
  if (!data?.length) { lista.innerHTML = '<p style="color:#888;padding:20px;text-align:center">Nenhum item ainda. Clique em "+ Novo item".</p>'; return; }
  lista.innerHTML = data.map(it => `
    <div style="background:#fff;border:1px solid #eee;border-radius:10px;padding:12px;display:flex;align-items:center;gap:12px">
      <div style="flex:1;min-width:0">
        <div style="font-weight:600;font-size:14px">${it.destaque ? '★ ' : ''}${it.titulo}</div>
        <div style="font-size:11px;color:#888;margin-top:4px">${it.area} · ${it.formato} · ${it.fonte || 'sem fonte'} ${it.ativo ? '' : '· INATIVO'}</div>
      </div>
      <button onclick="editarCuradoria('${it.id}')" style="background:none;border:1px solid #ddd;padding:6px 10px;border-radius:6px;cursor:pointer;font-size:12px">Editar</button>
      <button onclick="toggleCuradoria('${it.id}',${!it.ativo})" style="background:none;border:1px solid #ddd;padding:6px 10px;border-radius:6px;cursor:pointer;font-size:12px">${it.ativo ? 'Inativar' : 'Ativar'}</button>
      <button onclick="excluirCuradoria('${it.id}')" style="background:#EE2737;color:#fff;border:none;padding:6px 10px;border-radius:6px;cursor:pointer;font-size:12px">Excluir</button>
    </div>
  `).join('');
}

function abrirFormCuradoria(it) {
  document.getElementById('cur-id').value = it?.id || '';
  document.getElementById('cur-titulo').value = it?.titulo || '';
  document.getElementById('cur-desc').value = it?.descricao || '';
  document.getElementById('cur-url').value = it?.url || '';
  document.getElementById('cur-fonte').value = it?.fonte || '';
  document.getElementById('cur-area').value = it?.area || 'Qualidade';
  document.getElementById('cur-formato').value = it?.formato || 'video';
  document.getElementById('cur-dur').value = it?.duracao_min || '';
  document.getElementById('cur-nivel').value = it?.nivel || 'todos';
  document.getElementById('cur-destaque').checked = !!it?.destaque;
  document.getElementById('cur-form-title').textContent = it ? 'Editar item' : 'Novo item de curadoria';
  document.getElementById('modal-cur').style.display = 'flex';
}

async function editarCuradoria(id) {
  const { data } = await sb.from('curadoria_externa').select('*').eq('id', id).single();
  if (data) abrirFormCuradoria(data);
}

async function salvarCuradoria() {
  const id = document.getElementById('cur-id').value;
  const payload = {
    titulo: document.getElementById('cur-titulo').value.trim(),
    descricao: document.getElementById('cur-desc').value.trim() || null,
    url: document.getElementById('cur-url').value.trim(),
    fonte: document.getElementById('cur-fonte').value.trim() || null,
    area: document.getElementById('cur-area').value,
    formato: document.getElementById('cur-formato').value,
    duracao_min: parseInt(document.getElementById('cur-dur').value) || null,
    nivel: document.getElementById('cur-nivel').value,
    destaque: document.getElementById('cur-destaque').checked
  };
  if (!payload.titulo || !payload.url) { alert('Título e URL são obrigatórios'); return; }
  const op = id ? sb.from('curadoria_externa').update(payload).eq('id', id)
                : sb.from('curadoria_externa').insert(payload);
  const { error } = await op;
  if (error) { alert('Erro: ' + error.message); return; }
  document.getElementById('modal-cur').style.display = 'none';
  await carregarCuradoria();
}

async function toggleCuradoria(id, ativo) {
  await sb.from('curadoria_externa').update({ ativo }).eq('id', id);
  await carregarCuradoria();
}

async function excluirCuradoria(id) {
  if (!confirm('Excluir este item da curadoria?')) return;
  const { error } = await sb.from('curadoria_externa').delete().eq('id', id);
  if (error) { alert('Erro: ' + error.message); return; }
  await carregarCuradoria();
}
```

---

## 4. Chame `carregarCuradoria()` quando entrar na aba

No seu `setTab(name)` ou função equivalente, adicione:

```javascript
if (name === 'curadoria') carregarCuradoria();
```

---

Pronto. A aba de curadoria fica disponível para você adicionar/editar/excluir os links que aparecem para os colaboradores.
