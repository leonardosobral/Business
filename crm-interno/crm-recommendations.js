const escape=value=>String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));

export function renderRecommendations({container,items,onPrepareDraft}) {
  container.innerHTML=items.map((item,index)=>`<article class="crm-recommendation"><div><strong>${escape(item.title)}</strong><small>${escape(item.reason)}</small></div><div class="crm-recommendation-actions"><button type="button" data-prepare="${index}">Preparar campanha</button><button type="button" data-ignore="${index}" class="crm-link">Ignorar</button></div></article>`).join('');
  container.querySelectorAll('[data-prepare]').forEach(button=>button.onclick=()=>onPrepareDraft(items[Number(button.dataset.prepare)]));
  container.querySelectorAll('[data-ignore]').forEach(button=>button.onclick=()=>button.closest('.crm-recommendation').remove());
}
