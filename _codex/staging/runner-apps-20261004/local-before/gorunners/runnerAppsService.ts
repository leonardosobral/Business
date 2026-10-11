/**
 * Runner Apps service — consome o menu dinâmico de apps do Business
 * (https://business.roadrunners.run/api/portal/runner-apps/), com cache em
 * memória de 5 min e fallback estático.
 *
 * Estratégia:
 *   1. Se cache válido (idade < TTL) → devolve cache com source='cache'
 *   2. Fetch API com AbortSignal.timeout(3s), valida success=true e
 *      Array.isArray(groups), sanitiza URLs, popula cache, devolve source='api'
 *   3. API falhou: se cache "stale" existe (idade > TTL mas != null) →
 *      devolve cache stale com source='cache-stale'
 *   4. Sem cache: devolve fallback estático com source='fallback'
 *
 * Nunca lança — sempre retorna algo renderizável. Isso vale mais que
 * frescor pra um menu de apps.
 */

import { RUNNER_APPS_FALLBACK } from '../data/runnerAppsFallback';

// `?linha=principal` filtra a API do Business pros apps da linha principal
// (Road Runners, Open Results, Run BI, Go Runners...) — deixa fora eventos
// pontuais e integrações que vivem em outras "linhas" do portal.
const API_URL = 'https://business.roadrunners.run/api/portal/runner-apps/?linha=principal';
const TIMEOUT_MS = 3_000;
const TTL_MS = 5 * 60 * 1_000; // 5 min

export interface RunnerAppItem {
  id?: number;
  groupId?: number;
  order?: number;
  name?: string;
  label: string;
  href: string;
  target?: string;
  rel?: string;
  imgSrc: string;
  imgAlt?: string;
}

export interface RunnerAppGroup {
  id?: number;
  name?: string;
  order?: number;
  items: RunnerAppItem[];
}

export interface RunnerAppsPoweredBy {
  label?: string;
  href?: string;
  name?: string;
}

export interface RunnerAppsPayload {
  groups: RunnerAppGroup[];
  poweredBy?: RunnerAppsPoweredBy | null;
}

export type RunnerAppsSource = 'api' | 'cache' | 'cache-stale' | 'fallback';

export interface RunnerAppsResult extends RunnerAppsPayload {
  source: RunnerAppsSource;
  fetchedAt: string;
}

// ── Cache state (per-process) ────────────────────────────────────────────────
interface CacheEntry {
  payload: RunnerAppsPayload;
  fetchedAt: number;
}
let cache: CacheEntry | null = null;

// ── URL sanitizer ────────────────────────────────────────────────────────────
// Só aceita schemes seguros: http, https, ou path absoluto começando com "/".
// Bloqueia javascript:, data:, file:, etc. — não deveria vir da API, mas é
// defesa em profundidade.
function isSafeUrl(url: unknown): url is string {
  if (typeof url !== 'string' || url.length === 0) return false;
  if (url.startsWith('/')) return true;
  const lower = url.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

function pickString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

/**
 * Remove tags HTML simples do texto. A API às vezes bota <br> em `label`
 * (não só em `labelHtml`) — como o consumidor trata `label` como texto puro
 * e o React não renderiza HTML na interpolação, strip pra ficar legível.
 * Não é sanitizer completo (não escapa entities), mas suficiente pra
 * limpeza cosmética.
 */
function stripTags(value: string): string {
  return value.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
}

/**
 * A API do Business (ColdFusion) serializa as chaves em UPPERCASE por default
 * (SUCCESS, GROUPS, ITEMS, LABEL, HREF...). Normalizamos pra lowercase antes
 * de validar pra o consumo ficar case-insensitive.
 */
function lowerKeys(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(lowerKeys);
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k.toLowerCase()] = lowerKeys(v);
    }
    // Preserva camelCase esperado nas chaves do TS (groupId, imgSrc, imgAlt,
    // labelHtml, poweredBy) sobrescrevendo os aliases lowercase.
    for (const [from, to] of [
      ['groupid', 'groupId'],
      ['imgsrc', 'imgSrc'],
      ['imgalt', 'imgAlt'],
      ['labelhtml', 'labelHtml'],
      ['poweredby', 'poweredBy'],
    ] as const) {
      if (from in out && !(to in out)) out[to] = out[from];
    }
    return out;
  }
  return value;
}

/**
 * Normaliza + valida o payload cru vindo da API. Descarta itens com href ou
 * imgSrc inválidos. Preserva a ordem original (a API já ordena).
 */
function normalizePayload(raw: unknown): RunnerAppsPayload | null {
  if (!raw || typeof raw !== 'object') return null;
  const obj = lowerKeys(raw) as Record<string, unknown>;
  // Aceita success === true OR truthy (ColdFusion pode devolver 1)
  if (obj.success !== true && obj.success !== 1 && obj.success !== 'true') return null;
  if (!Array.isArray(obj.groups)) return null;

  const groups: RunnerAppGroup[] = [];
  for (const rawGroup of obj.groups as unknown[]) {
    if (!rawGroup || typeof rawGroup !== 'object') continue;
    const g = rawGroup as Record<string, unknown>;
    // ColdFusion serializa boolean como 0/1
    if (g.active === false || g.active === 0) continue;

    const itemsRaw = Array.isArray(g.items) ? (g.items as unknown[]) : [];
    const items: RunnerAppItem[] = [];
    for (const rawItem of itemsRaw) {
      if (!rawItem || typeof rawItem !== 'object') continue;
      const it = rawItem as Record<string, unknown>;
      if (it.active === false || it.active === 0) continue;

      const href = pickString(it.href);
      const imgSrc = pickString(it.imgSrc);
      if (!isSafeUrl(href) || !isSafeUrl(imgSrc)) continue;
      const label = stripTags(pickString(it.label) || pickString(it.name));
      if (!label) continue;

      items.push({
        id: typeof it.id === 'number' ? it.id : undefined,
        groupId: typeof it.groupId === 'number' ? it.groupId : undefined,
        order: typeof it.order === 'number' ? it.order : undefined,
        name: stripTags(pickString(it.name)) || label,
        label,
        href,
        target: pickString(it.target),
        rel: pickString(it.rel),
        imgSrc,
        imgAlt: stripTags(pickString(it.imgAlt)) || label,
      });
    }

    // Só inclui grupo com pelo menos 1 item válido
    if (items.length === 0) continue;

    groups.push({
      id: typeof g.id === 'number' ? g.id : undefined,
      name: pickString(g.name),
      order: typeof g.order === 'number' ? g.order : undefined,
      items,
    });
  }

  if (groups.length === 0) return null;

  let poweredBy: RunnerAppsPoweredBy | null = null;
  if (obj.poweredBy && typeof obj.poweredBy === 'object') {
    const pb = obj.poweredBy as Record<string, unknown>;
    const pbHref = pickString(pb.href);
    poweredBy = {
      label: pickString(pb.label),
      href: isSafeUrl(pbHref) ? pbHref : undefined,
      name: pickString(pb.name),
    };
  }

  return { groups, poweredBy };
}

// ── Public API ───────────────────────────────────────────────────────────────
export async function getRunnerApps(): Promise<RunnerAppsResult> {
  const now = Date.now();

  // 1) Cache fresco
  if (cache && now - cache.fetchedAt < TTL_MS) {
    return { ...cache.payload, source: 'cache', fetchedAt: new Date(cache.fetchedAt).toISOString() };
  }

  // 2) Tentar API
  try {
    const res = await fetch(API_URL, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (res.ok) {
      const raw = await res.json();
      const payload = normalizePayload(raw);
      if (payload) {
        cache = { payload, fetchedAt: now };
        return { ...payload, source: 'api', fetchedAt: new Date(now).toISOString() };
      }
    }
  } catch (err) {
    // silencioso — cai no fallback abaixo
    console.warn('[runnerApps] fetch failed:', (err as Error)?.message ?? err);
  }

  // 3) Cache stale (última resposta válida, mesmo expirada)
  if (cache) {
    return { ...cache.payload, source: 'cache-stale', fetchedAt: new Date(cache.fetchedAt).toISOString() };
  }

  // 4) Fallback estático
  return { ...RUNNER_APPS_FALLBACK, source: 'fallback', fetchedAt: new Date(now).toISOString() };
}

/** Test-only helper — permite testes resetarem estado entre casos. */
export function _resetRunnerAppsCacheForTest(): void {
  cache = null;
}

/** Export só pra teste — mesmo módulo, sem shims. */
export const _testables = { normalizePayload, isSafeUrl };
