import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const WORKSPACE = "/Users/Shared/Projects/RunnerHub/Business";
const BUILD_DIR = path.join(WORKSPACE, ".codex-build/nsc-corre");
const SKILL_DIR = "/Users/leonardosobral/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.12148/skills/presentations";
const RUNTIME_PYTHON = "/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const VERSION = process.env.DECK_VERSION || "v1";
const FINAL_PPTX = path.join(WORKSPACE, `output/presentation/NSC_Corre_Parceria_RunnerHub_${VERSION}.pptx`);
const CANDIDATE_PPTX = path.join(BUILD_DIR, "finalizer", `candidate-${VERSION}.pptx`);
const RECEIPT = path.join(BUILD_DIR, "finalizer", `NSC_Corre_${VERSION}.validation.json`);

const W = 1280;
const H = 720;
const FONT = "Avenir Next";

const C = {
  dark: "#141516",
  charcoal: "#252729",
  graphite: "#3D4144",
  paper: "#F4F2EC",
  white: "#FFFFFF",
  ink: "#17191A",
  muted: "#6E7377",
  light: "#D9DDDF",
  yellow: "#F7B500",
  orange: "#FF6413",
  cyan: "#00A8CE",
  green: "#29B37D",
  red: "#E6513E",
};

const A = {
  asphalt: path.join(WORKSPACE, "assets/rr_fundo_horiz.jpg"),
  biAsphalt: path.join(WORKSPACE, "assets/rbi_fundo_horizontal.jpg"),
  runnerWhite: path.join(WORKSPACE, "assets/rh_branco.png"),
  runnerDark: path.join(WORKSPACE, "assets/rh_grafite.png"),
  ecosystem: path.join(WORKSPACE, "assets/img/marcas.png"),
  nscOrange: path.join(BUILD_DIR, "assets/nsc-laranja.png"),
  clubLogo: path.join(BUILD_DIR, "assets/clube-nsc-logo.svg"),
};

const MIME = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
};

const assetCache = new Map();
async function assetPayload(file) {
  if (!assetCache.has(file)) {
    const ext = path.extname(file).toLowerCase();
    if (ext === ".svg") {
      const source = await fs.readFile(file, "utf8");
      const embedded = source.match(/data:(image\/(?:png|jpeg|webp));base64,([^\"]+)/);
      if (embedded) {
        assetCache.set(file, {
          blob: new Uint8Array(Buffer.from(embedded[2], "base64")),
          contentType: embedded[1],
        });
      } else {
        assetCache.set(file, { blob: new Uint8Array(Buffer.from(source)), contentType: "image/svg+xml" });
      }
    } else {
      assetCache.set(file, {
        blob: new Uint8Array(await fs.readFile(file)),
        contentType: MIME[ext] || "application/octet-stream",
      });
    }
  }
  return assetCache.get(file);
}

async function image(slide, file, position, options = {}) {
  const payload = await assetPayload(file);
  return slide.images.add({
    blob: payload.blob,
    contentType: payload.contentType,
    alt: options.alt || path.basename(file),
    fit: options.fit || "contain",
    position,
    ...(options.geometry ? { geometry: options.geometry } : {}),
    ...(options.borderRadius ? { borderRadius: options.borderRadius } : {}),
    ...(options.crop ? { crop: options.crop } : {}),
  });
}

function box(slide, x, y, w, h, fill, options = {}) {
  return slide.shapes.add({
    geometry: options.geometry || "rect",
    position: { left: x, top: y, width: w, height: h, ...(options.rotation ? { rotation: options.rotation } : {}) },
    fill,
    line: options.line || { fill: "none", width: 0 },
    ...(options.radius ? { borderRadius: options.radius } : {}),
    ...(options.shadow ? { shadow: options.shadow } : {}),
    ...(options.name ? { name: options.name } : {}),
  });
}

function line(slide, x, y, w, h, color, width = 2) {
  if (w < 0) { x += w; w = Math.abs(w); }
  if (h < 0) { y += h; h = Math.abs(h); }
  return slide.shapes.add({
    geometry: "line",
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: color, width },
  });
}

function text(slide, value, x, y, w, h, options = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left: x, top: y, width: w, height: h },
    fill: options.fill || "none",
    line: options.line || { fill: "none", width: 0 },
    ...(options.radius ? { borderRadius: options.radius } : {}),
  });
  if (Array.isArray(value) || typeof value === "object") shape.text.set(value);
  else shape.text = value;
  shape.text.style = {
    typeface: options.typeface || FONT,
    fontSize: options.size || 22,
    color: options.color || C.ink,
    bold: options.bold || false,
    italic: options.italic || false,
    alignment: options.align || "left",
    verticalAlignment: options.valign || "top",
    autoFit: options.autoFit || "shrinkText",
    wrap: "square",
    lineSpacing: options.lineSpacing || 1,
    insets: options.insets || { top: 0, right: 0, bottom: 0, left: 0 },
  };
  return shape;
}

function pill(slide, label, x, y, w, fill, color = C.ink) {
  box(slide, x, y, w, 30, fill, { geometry: "roundRect", radius: "rounded-full" });
  text(slide, label, x + 10, y + 3, w - 20, 24, { size: 13, bold: true, color, align: "center", valign: "middle" });
}

function smallRule(slide, x, y, w = 70, color = C.yellow) {
  box(slide, x, y, w, 6, color, { geometry: "roundRect", radius: "rounded-full" });
}

function titleBlock(slide, kicker, titleValue, subtitle, options = {}) {
  const dark = options.dark || false;
  const ink = dark ? C.white : C.ink;
  const kickerWidth = kicker.toLowerCase().startsWith("apêndice")
    ? 170
    : Math.max(110, Math.min(280, kicker.length * 8 + 42));
  pill(slide, kicker.toUpperCase(), 64, 38, kickerWidth, dark ? C.yellow : C.dark, dark ? C.ink : C.white);
  text(slide, titleValue, 64, 80, 1152, options.titleHeight || 74, { size: options.titleSize || 42, bold: true, color: ink, lineSpacing: 0.94 });
  if (subtitle) text(slide, subtitle, 64, options.subtitleTop || 151, 1130, 44, { size: 19, color: dark ? C.light : C.muted });
}

async function footer(slide, number, dark = false) {
  const color = dark ? "#B7BCBF" : C.muted;
  line(slide, 64, 679, 1152, 0, dark ? "#424649" : "#D7D9D8", 1);
  await image(slide, dark ? A.runnerWhite : A.runnerDark, { left: 64, top: 688, width: 138, height: 23 }, { alt: "RunnerHub" });
  text(slide, String(number).padStart(2, "0"), 1166, 687, 50, 22, { size: 13, bold: true, color, align: "right" });
}

function notes(slide, body) {
  slide.speakerNotes.textFrame.setText(body);
}

function dot(slide, x, y, size, fill, label, labelColor = C.white) {
  box(slide, x, y, size, size, fill, { geometry: "ellipse" });
  if (label) text(slide, label, x, y + 1, size, size - 2, { size: Math.max(12, size * 0.35), bold: true, color: labelColor, align: "center", valign: "middle" });
}

function metric(slide, value, label, x, y, w, accent = C.yellow, dark = false) {
  const ink = dark ? C.white : C.ink;
  smallRule(slide, x, y, 48, accent);
  text(slide, value, x, y + 14, w, 64, { size: 47, bold: true, color: ink, lineSpacing: 0.9 });
  text(slide, label, x, y + 76, w, 56, { size: 17, color: dark ? C.light : C.muted, lineSpacing: 1.05 });
}

const { applyPresentationChartFont, finalizePresentation } = await import(
  pathToFileURL(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs")).href,
);

await fs.mkdir(path.dirname(FINAL_PPTX), { recursive: true });
await fs.mkdir(path.dirname(CANDIDATE_PPTX), { recursive: true });

const presentation = Presentation.create({ slideSize: { width: W, height: H } });

// 01 — Cover
{
  const slide = presentation.slides.add();
  slide.background.fill = C.dark;
  await image(slide, A.asphalt, { left: 0, top: 0, width: W, height: H }, { fit: "cover", alt: "Textura de asfalto RunnerHub" });
  box(slide, 0, 0, W, H, "#0D0E0F/78");
  box(slide, 0, 0, 18, H, C.yellow);
  box(slide, 1008, 0, 272, 88, C.orange, { geometry: "roundRect", radius: 22 });
  await image(slide, A.runnerWhite, { left: 72, top: 56, width: 188, height: 34 }, { alt: "RunnerHub" });
  box(slide, 1088, 25, 126, 74, C.white, { geometry: "roundRect", radius: 14 });
  await image(slide, A.nscOrange, { left: 1101, top: 33, width: 100, height: 58 }, { alt: "NSC" });
  pill(slide, "PROPOSTA DE PLATAFORMA ANUAL", 72, 150, 296, C.yellow, C.ink);
  text(slide, [
    [{ run: "NSC", textStyle: { bold: true, color: C.white } }, { run: " CORRE", textStyle: { bold: true, color: C.yellow } }],
  ], 72, 212, 900, 112, { size: 82, bold: true, color: C.white, lineSpacing: 0.88 });
  text(slide, "A casa da corrida catarinense", 76, 330, 820, 58, { size: 35, color: C.white, bold: true });
  text(slide, "Dados confiáveis, conteúdo útil, comunidade, benefícios e experiências ao longo de 365 dias.", 76, 401, 790, 78, { size: 23, color: C.light, lineSpacing: 1.08 });
  line(slide, 76, 540, 820, 0, "#8A8F92", 1);
  text(slide, "RUNNERHUB × NSC", 76, 560, 350, 32, { size: 16, bold: true, color: C.yellow });
  text(slide, "Setembro de 2026", 76, 598, 300, 28, { size: 15, color: C.light });
  notes(slide, [
    "Objetivo: propor uma plataforma anual para posicionar a NSC como referência catarinense em corrida e a RunnerHub como sua camada de inteligência e dados.",
    "Imagem: ativo institucional RunnerHub, assets/rr_fundo_horiz.jpg.",
  ]);
}

// 02 — Opportunity
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Oportunidade", "Santa Catarina já corre. Falta um lugar que organize essa conversa.", "A densidade do calendário cria pauta, serviço, comunidade e receita durante o ano inteiro.", { titleSize: 40 });

  metric(slide, "559", "corridas de rua ativas e não canceladas no calendário RunnerHub em 2025", 72, 230, 250, C.yellow);
  metric(slide, "+38%", "crescimento do calendário cadastrado versus 2024", 72, 396, 250, C.orange);
  pill(slide, "5º NO PAÍS EM 2025", 72, 570, 250, C.dark, C.white);

  const chart = slide.charts.add("bar", {
    position: { left: 380, top: 218, width: 812, height: 350 },
    title: "Calendário cadastrado na RunnerHub — Santa Catarina",
    titlePlacement: "aboveChart",
    titleTextStyle: { typeface: FONT, fontSize: 20, fill: C.ink, bold: true },
    categories: ["2024", "2025", "2026"],
    series: [{ name: "Provas", values: [405, 559, 596], fill: C.yellow }],
    barOptions: { direction: "column", grouping: "clustered", gapWidth: 56, varyColors: false },
    hasLegend: false,
    xAxis: { visible: true, textStyle: { typeface: FONT, fontSize: 16, fill: C.ink, bold: true }, line: { style: "solid", fill: "#C8CBCC", width: 1 } },
    yAxis: { visible: false, min: 0, max: 650, majorGridlines: null },
    dataLabels: { showValue: true, position: "outEnd", textStyle: { typeface: FONT, fontSize: 18, fill: C.ink, bold: true } },
    chartFill: C.paper,
    chartLine: { fill: "none", width: 0 },
    plotAreaFill: C.paper,
    plotAreaLine: { fill: "none", width: 0 },
  });
  applyPresentationChartFont(chart, { fontFamily: FONT });
  box(slide, 380, 586, 812, 66, C.dark, { geometry: "roundRect", radius: 14 });
  text(slide, "Até 10/09, 2026 já soma 399 provas no período", 404, 599, 520, 28, { size: 19, bold: true, color: C.white });
  text(slide, "+43,5% vs. 2025", 940, 596, 224, 32, { size: 24, bold: true, color: C.yellow, align: "right" });
  text(slide, "Base RunnerHub. Calendário cadastrado, não uma declaração de provas concluídas.", 72, 651, 810, 19, { size: 11.5, color: C.muted });
  await footer(slide, 2);
  notes(slide, [
    "Fonte: base oficial RunnerHub fornecida pelo usuário. Corte em 10/09/2026.",
    "Dados: calendário cadastrado SC — 2024: 405; 2025: 559; 2026: 596. Até 10/09 — 2024: 226; 2025: 278; 2026: 399.",
    "Crescimentos: 2025 vs 2024 = 38,0%; 2026 vs 2025 = 6,6%; período até 10/09: 2025 vs 2024 = 23,0%; 2026 vs 2025 = 43,5%.",
    "Posição nacional: 6º em 2024; 5º em 2025 e 2026.",
  ]);
}

// 03 — Methodological contrast
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  titleBlock(slide, "Precisão editorial", "O mesmo estado pode virar duas manchetes. O critério decide a leitura.", "Duas fontes públicas e operacionais podem descrever Santa Catarina com universos diferentes.", { titleSize: 38 });

  box(slide, 64, 220, 520, 360, "#F1F3F4", { geometry: "roundRect", radius: 22 });
  pill(slide, "ABRACEO / CBAt", 92, 246, 184, C.orange, C.white);
  text(slide, "478", 92, 292, 210, 78, { size: 62, bold: true, color: C.ink });
  text(slide, "provas em SC em 2025", 92, 365, 390, 36, { size: 21, bold: true, color: C.ink });
  text(slide, "+71%", 92, 425, 150, 45, { size: 34, bold: true, color: C.orange });
  text(slide, "crescimento divulgado", 92, 466, 220, 28, { size: 16, color: C.muted });
  text(slide, "Fontes declaradas: CBAt, federações estaduais e DF. Sem microdados públicos acessíveis no material consultado.", 92, 515, 436, 46, { size: 15, color: C.muted, lineSpacing: 1.05 });

  box(slide, 696, 220, 520, 360, C.dark, { geometry: "roundRect", radius: 22 });
  pill(slide, "RUNNERHUB", 724, 246, 156, C.yellow, C.ink);
  text(slide, "559", 724, 292, 210, 78, { size: 62, bold: true, color: C.white });
  text(slide, "provas ativas e não canceladas em SC em 2025", 724, 365, 420, 58, { size: 21, bold: true, color: C.white, lineSpacing: 1.02 });
  text(slide, "+38%", 724, 435, 150, 45, { size: 34, bold: true, color: C.yellow });
  text(slide, "crescimento do calendário", 724, 476, 250, 28, { size: 16, color: C.light });
  text(slide, "Base operacional contínua do ecossistema RunnerHub. O indicador não mede o mesmo universo da ABRACEO.", 724, 515, 436, 46, { size: 15, color: C.light, lineSpacing: 1.05 });

  dot(slide, 608, 335, 64, C.yellow, "≠", C.ink);
  box(slide, 162, 602, 956, 54, "#FFF1DA", { geometry: "roundRect", radius: 14, line: { style: "solid", fill: "#FFD789", width: 1 } });
  text(slide, "A NSC ganha um filtro técnico para não tratar cadastro parcial como o total do mercado.", 186, 615, 908, 28, { size: 20, bold: true, color: C.ink, align: "center" });
  text(slide, "Fontes: ABRACEO/Máquina do Esporte e base RunnerHub. Comparação de medidas, não cálculo de cobertura.", 64, 661, 960, 18, { size: 11.5, color: C.muted });
  await footer(slide, 3);
  notes(slide, [
    "Fontes externas:",
    "https://maquinadoesporte.com.br/running/corridas-de-rua-crescem-85-no-brasil-em-2025/",
    "https://abraceo.com.br/4o-summit-abraceo-cbat-corridas-de-rua-cresceram-85-em-2025-no-brasil/",
    "Fonte RunnerHub: base oficial fornecida pelo usuário.",
    "Nota metodológica: não calcular cobertura, subnotificação ou erro de uma fonte pela diferença entre 478 e 559. Os universos e critérios de inclusão não são publicamente equivalentes. O argumento seguro é exigir fonte, critério, corte e cobertura em qualquer pauta.",
  ]);
}

// 04 — Evidence chain
{
  const slide = presentation.slides.add();
  slide.background.fill = C.dark;
  await image(slide, A.biAsphalt, { left: 0, top: 0, width: W, height: H }, { fit: "cover", alt: "Textura de dados RunnerHub" });
  box(slide, 0, 0, W, H, "#0B0C0D/86");
  titleBlock(slide, "Diferencial RunnerHub", "Dados que conectam cadastro, execução e resultado.", "O resultado publicado confirma execução e abre a leitura de perfil, distância, tempo, território e recorrência.", { dark: true, titleSize: 40 });

  const steps = [
    { x: 74, n: "9,2 mil", l: "eventos mapeados\nem 2025", c: C.yellow },
    { x: 354, n: "84,1%", l: "dos eventos com base\nanalítica disponível", c: C.orange },
    { x: 634, n: "5,3 mi", l: "conclusões registradas\nem 2025", c: C.cyan },
    { x: 914, n: "11 mi+", l: "resultados no acervo\nOpen Results", c: C.green },
  ];
  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    box(slide, s.x, 274, 236, 200, "#222426/92", { geometry: "roundRect", radius: 22, line: { style: "solid", fill: "#44484B", width: 1 } });
    dot(slide, s.x + 88, 244, 60, s.c, String(i + 1), C.ink);
    text(slide, s.n, s.x + 18, 324, 200, 56, { size: 42, bold: true, color: C.white, align: "center" });
    text(slide, s.l, s.x + 24, 390, 188, 60, { size: 17, color: C.light, align: "center", lineSpacing: 1.08 });
    if (i < steps.length - 1) line(slide, s.x + 236, 372, 44, 0, "#777C80", 2);
  }
  box(slide, 102, 520, 1076, 92, "#F7B500", { geometry: "roundRect", radius: 20 });
  text(slide, "Registro diz que a prova foi informada. Resultado publicado mostra que ela aconteceu e revela o que veio depois.", 140, 538, 1000, 58, { size: 25, bold: true, color: C.ink, align: "center", valign: "middle", lineSpacing: 1.02 });
  text(slide, "Fonte: Brasil que Corre — Provas 2025. ‘Conclusões’ não equivale a pessoas únicas.", 74, 651, 860, 20, { size: 11.5, color: "#AEB3B6" });
  await footer(slide, 4, true);
  notes(slide, [
    "Fonte: /Users/leonardosobral/Downloads/BrasilQueCorreProvas2025_v3.10.3 (1).pdf, páginas 2–3.",
    "O estudo reporta 9,2 mil eventos mapeados, 5,3 milhões de concluintes e cobertura analítica de 84,1% dos eventos mapeados. Os demais 15,9% incluem provas sem resultado publicado, sem confirmação de execução, não cronometradas ou não competitivas.",
    "O acervo Open Results contém mais de 11 milhões de resultados republicados, conforme o estudo.",
    "Usar ‘conclusões registradas’ ou ‘resultados’, nunca ‘corredores únicos’.",
    "Imagem: ativo institucional RunnerHub, assets/rbi_fundo_horizontal.jpg.",
  ]);
}

// 05 — Audience
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Audiência", "Quem corre oferece uma agenda editorial muito maior que prova e pódio.", "A base revela uma audiência ampla, acessível e recorrente para conteúdo de serviço e histórias locais.", { titleSize: 38 });

  const gender = slide.charts.add("doughnut", {
    position: { left: 68, top: 215, width: 348, height: 322 },
    title: "Perfil por gênero",
    titlePlacement: "aboveChart",
    titleTextStyle: { typeface: FONT, fontSize: 20, fill: C.ink, bold: true },
    categories: ["Mulheres", "Homens"],
    series: [{
      name: "Participação",
      values: [52.9, 47.1],
      points: [{ idx: 0, fill: C.orange }, { idx: 1, fill: "#D6D9DA" }],
    }],
    doughnutOptions: { holeSize: 72, firstSliceAngle: 270 },
    hasLegend: false,
    chartFill: C.paper,
    chartLine: { fill: "none", width: 0 },
    plotAreaFill: C.paper,
    plotAreaLine: { fill: "none", width: 0 },
  });
  applyPresentationChartFont(gender, { fontFamily: FONT });
  text(slide, "52,9%", 156, 336, 172, 44, { size: 34, bold: true, color: C.orange, align: "center" });
  text(slide, "mulheres", 166, 380, 152, 26, { size: 16, bold: true, color: C.muted, align: "center" });

  const distance = slide.charts.add("doughnut", {
    position: { left: 466, top: 215, width: 348, height: 322 },
    title: "Distância dos resultados",
    titlePlacement: "aboveChart",
    titleTextStyle: { typeface: FONT, fontSize: 20, fill: C.ink, bold: true },
    categories: ["Até 5 km", "Acima de 5 km"],
    series: [{
      name: "Participação",
      values: [59.1, 40.9],
      points: [{ idx: 0, fill: C.yellow }, { idx: 1, fill: "#D6D9DA" }],
    }],
    doughnutOptions: { holeSize: 72, firstSliceAngle: 270 },
    hasLegend: false,
    chartFill: C.paper,
    chartLine: { fill: "none", width: 0 },
    plotAreaFill: C.paper,
    plotAreaLine: { fill: "none", width: 0 },
  });
  applyPresentationChartFont(distance, { fontFamily: FONT });
  text(slide, "59,1%", 554, 336, 172, 44, { size: 34, bold: true, color: "#C58B00", align: "center" });
  text(slide, "até 5 km", 564, 380, 152, 26, { size: 16, bold: true, color: C.muted, align: "center" });

  box(slide, 866, 230, 328, 120, C.dark, { geometry: "roundRect", radius: 20 });
  text(slide, "50,5%", 892, 248, 278, 54, { size: 43, bold: true, color: C.yellow });
  text(slide, "Millennials", 894, 302, 270, 30, { size: 18, color: C.white, bold: true });
  box(slide, 866, 372, 328, 74, C.white, { geometry: "roundRect", radius: 18, line: { style: "solid", fill: "#D8DADB", width: 1 } });
  text(slide, "Q4 concentra 33,5%", 890, 390, 280, 30, { size: 21, bold: true, color: C.ink });
  box(slide, 866, 468, 328, 74, C.white, { geometry: "roundRect", radius: 18, line: { style: "solid", fill: "#D8DADB", width: 1 } });
  text(slide, "Novembro chega a 13,4%", 890, 486, 280, 30, { size: 21, bold: true, color: C.ink });

  box(slide, 92, 570, 1102, 70, "#E7F6FA", { geometry: "roundRect", radius: 18 });
  text(slide, "Conteúdo de saúde, treinamento, calendário regional e histórias de iniciantes pode ampliar a audiência além dos atletas de elite.", 120, 589, 1044, 40, { size: 20, bold: true, color: C.ink, align: "center" });
  text(slide, "Fonte: Brasil que Corre — Provas 2025.", 64, 657, 500, 18, { size: 11.5, color: C.muted });
  await footer(slide, 5);
  notes(slide, [
    "Fonte: /Users/leonardosobral/Downloads/BrasilQueCorreProvas2025_v3.10.3 (1).pdf, páginas 3, 5, 11 e 12.",
    "Dados: 52,9% mulheres; 47,1% homens; 59,1% dos resultados em distâncias de até 5 km; Millennials 50,5%; quarto trimestre 33,5%; novembro 13,4%.",
    "A frase sobre oportunidade editorial é uma inferência estratégica da RunnerHub baseada no perfil, recorrência e sazonalidade observados.",
  ]);
}

// 06 — Platform
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  titleBlock(slide, "A propriedade", "NSC Corre: a plataforma anual da corrida catarinense.", "Um mesmo guarda-chuva conecta utilidade, conteúdo, comunidade e experiência.", { titleSize: 40 });
  pill(slide, "NSC: 6 EMISSORAS • 295 MUNICÍPIOS • 3,4 MI/DIA", 736, 201, 480, "#FFF2E9", C.orange);

  const cx = 640, cy = 397;
  box(slide, cx - 142, cy - 78, 284, 156, C.dark, { geometry: "roundRect", radius: 26, shadow: "shadow-md" });
  text(slide, "NSC", cx - 112, cy - 44, 90, 46, { size: 34, bold: true, color: C.white, align: "right" });
  text(slide, "CORRE", cx - 15, cy - 44, 132, 46, { size: 34, bold: true, color: C.yellow });
  text(slide, "A casa da corrida catarinense", cx - 110, cy + 14, 220, 28, { size: 15, color: C.light, align: "center" });

  const nodes = [
    { x: 74, y: 250, w: 350, h: 130, t: "UTILIDADE", d: "Calendário confiável, mudanças, cancelamentos e guia de provas.", c: C.yellow },
    { x: 856, y: 250, w: 350, h: 130, t: "CONTEÚDO", d: "Agenda, histórias locais, especialistas e dados que viram pauta.", c: C.orange },
    { x: 74, y: 444, w: 350, h: 130, t: "COMUNIDADE", d: "Clubes, assessorias, desafios, ranking e conversa regional.", c: C.cyan },
    { x: 856, y: 444, w: 350, h: 130, t: "EXPERIÊNCIA", d: "Treinos, ativações, eventos parceiros e cobertura ao vivo.", c: C.green },
  ];
  for (const n of nodes) {
    box(slide, n.x, n.y, n.w, n.h, "#F4F5F4", { geometry: "roundRect", radius: 20, line: { style: "solid", fill: "#DFE2E2", width: 1 } });
    box(slide, n.x, n.y, 9, n.h, n.c, { geometry: "roundRect", radius: "rounded-full" });
    text(slide, n.t, n.x + 28, n.y + 22, 290, 27, { size: 18, bold: true, color: C.ink });
    text(slide, n.d, n.x + 28, n.y + 58, 292, 56, { size: 16.5, color: C.muted, lineSpacing: 1.06 });
  }
  line(slide, 424, 314, 74, 55, "#A8ADAF", 2);
  line(slide, 782, 369, 74, -55, "#A8ADAF", 2);
  line(slide, 424, 510, 74, -55, "#A8ADAF", 2);
  line(slide, 782, 455, 74, 55, "#A8ADAF", 2);

  box(slide, 96, 592, 1088, 60, C.dark, { geometry: "roundRect", radius: 16 });
  text(slide, "RunnerHub estrutura o dado e a jornada. NSC transforma isso em alcance, narrativa e receita.", 126, 609, 1028, 28, { size: 17.5, bold: true, color: C.white, align: "center" });
  await footer(slide, 6);
  notes(slide, [
    "Proposta conceitual RunnerHub. Os quatro pilares são componentes a co-desenhar com a NSC.",
    "Evidências de capacidade NSC: TV, rádio, digital, imprensa e experiências presenciais integradas.",
    "Fontes: https://nsc.com.br/marcas-nsc/nsc-tv/ e https://nsc.com.br/quem-somos/.",
  ]);
}

// 07 — Journey
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Jornada", "Uma relação de 365 dias entre intenção, preparação e conquista.", "Cada etapa da jornada gera serviço para o corredor e inventário para a NSC.", { titleSize: 40 });

  const stages = ["DESCOBRE", "ESCOLHE", "PREPARA", "CORRE", "CONFIRMA", "COMPARTILHA", "RECOMEÇA"];
  const runner = ["agenda", "comparação", "treino", "prova", "resultado", "história", "nova meta"];
  const nsc = ["pauta", "serviço", "conteúdo", "cobertura", "dados", "comunidade", "CRM opt-in"];
  const startX = 278, step = 148;
  line(slide, startX + 28, 296, step * 6, 0, "#B8BCBE", 4);
  for (let i = 0; i < stages.length; i++) {
    const x = startX + i * step;
    dot(slide, x, 264, 64, i === 3 ? C.orange : C.dark, String(i + 1), i === 3 ? C.white : C.yellow);
    text(slide, stages[i], x - 34, 337, 132, 25, { size: 14.5, bold: true, color: C.ink, align: "center" });
    text(slide, runner[i], x - 42, 376, 148, 24, { size: 14.5, color: C.muted, align: "center" });
    text(slide, nsc[i], x - 42, 441, 148, 24, { size: 14.5, bold: true, color: i === 3 ? C.orange : C.ink, align: "center" });
  }
  pill(slide, "CORREDOR", 64, 374, 152, C.white, C.ink);
  pill(slide, "NSC + RUNNERHUB", 64, 438, 166, "#E7EEF0", C.ink);
  box(slide, 116, 535, 1048, 78, C.dark, { geometry: "roundRect", radius: 18 });
  text(slide, "A corrida ganha continuidade como hábito editorial, benefício recorrente e plataforma comercial.", 150, 554, 980, 44, { size: 23, bold: true, color: C.white, align: "center" });
  await footer(slide, 7);
  notes(slide, [
    "Proposta conceitual RunnerHub. A etapa ‘inscrição’ foi deliberadamente descrita como escolha/comparação, pois a RunnerHub pode direcionar o atleta sem afirmar que processa toda inscrição.",
    "CRM e segmentação devem operar somente com consentimento e governança LGPD.",
  ]);
}

// 08 — Clube NSC
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  titleBlock(slide, "Novo motor de valor", "Corre no Clube: benefício que transforma audiência em relação.", "Uma vertical esportiva dentro do Clube NSC pode conectar assinatura, economia, experiência e dados consentidos.", { titleSize: 39, titleHeight: 92, subtitleTop: 169 });

  box(slide, 64, 222, 280, 370, C.dark, { geometry: "roundRect", radius: 24 });
  pill(slide, "PROPOSTA", 88, 246, 118, C.yellow, C.ink);
  box(slide, 88, 296, 232, 142, C.white, { geometry: "roundRect", radius: 18 });
  await image(slide, A.clubLogo, { left: 148, top: 309, width: 112, height: 108 }, { alt: "Clube NSC" });
  text(slide, "CORRE", 100, 449, 208, 45, { size: 34, bold: true, color: C.yellow, align: "center" });
  text(slide, "benefício esportivo para assinantes", 100, 502, 208, 48, { size: 16.5, color: C.light, align: "center", lineSpacing: 1.08 });

  const benefits = [
    { y: 222, n: "01", t: "VAGA COM VANTAGEM", d: "Descontos, lotes antecipados e cotas limitadas em provas parceiras.", c: C.orange },
    { y: 312, n: "02", t: "PREPARE-SE MELHOR", d: "Academias, fisioterapia, laboratórios, nutrição e recuperação.", c: C.yellow },
    { y: 402, n: "03", t: "VIVA A PROVA", d: "Treinos, preview de percurso, retirada VIP e hospitalidade.", c: C.cyan },
    { y: 492, n: "04", t: "CORRA E GANHE", d: "Desafios, recorrência e recompensas com consentimento do usuário.", c: C.green },
  ];
  for (const b of benefits) {
    box(slide, 382, b.y, 492, 76, "#F4F5F4", { geometry: "roundRect", radius: 16 });
    dot(slide, 398, b.y + 15, 46, b.c, b.n, C.ink);
    text(slide, b.t, 458, b.y + 12, 390, 23, { size: 16.5, bold: true, color: C.ink });
    text(slide, b.d, 458, b.y + 38, 390, 31, { size: 14.5, color: C.muted, lineSpacing: 1.03 });
  }

  box(slide, 910, 222, 306, 370, "#FFF2E9", { geometry: "roundRect", radius: 24, line: { style: "solid", fill: "#FFD1B8", width: 1 } });
  text(slide, "A EQUAÇÃO", 936, 247, 252, 24, { size: 16, bold: true, color: C.orange });
  text(slide, "Assinante", 936, 292, 110, 24, { size: 18, bold: true, color: C.ink });
  text(slide, "economia + acesso", 1050, 294, 138, 22, { size: 15, color: C.muted, align: "right" });
  line(slide, 936, 329, 252, 0, "#F1B897", 1);
  text(slide, "NSC", 936, 349, 110, 24, { size: 18, bold: true, color: C.ink });
  text(slide, "aquisição + retenção", 1044, 351, 144, 22, { size: 15, color: C.muted, align: "right" });
  line(slide, 936, 386, 252, 0, "#F1B897", 1);
  text(slide, "Marcas", 936, 406, 110, 24, { size: 18, bold: true, color: C.ink });
  text(slide, "conversão + contexto", 1042, 408, 146, 22, { size: 15, color: C.muted, align: "right" });
  line(slide, 936, 443, 252, 0, "#F1B897", 1);
  text(slide, "RunnerHub", 936, 463, 110, 24, { size: 18, bold: true, color: C.ink });
  text(slide, "distribuição + medição", 1036, 465, 152, 22, { size: 15, color: C.muted, align: "right" });
  box(slide, 936, 511, 252, 54, C.orange, { geometry: "roundRect", radius: 13 });
  text(slide, "Benefício gera dado de valor", 950, 524, 224, 28, { size: 16.5, bold: true, color: C.white, align: "center" });

  text(slide, "O Clube NSC declara 500+ parceiros em SC e benefícios de até 50%. Os itens acima são propostas sujeitas a negociação.", 64, 626, 1134, 34, { size: 12.5, color: C.muted, align: "center" });
  await footer(slide, 8);
  notes(slide, [
    "Fonte oficial Clube NSC: https://clubensc.com.br/sobre-o-clube/ e https://clubensc.com.br/.",
    "O Clube NSC é apresentado como programa de benefícios exclusivo para assinantes NSC Total, com mais de 500 parceiros em Santa Catarina, descontos de até 50%, eventos e promoções exclusivas.",
    "Todos os benefícios listados neste slide são propostas. Dependem de negociação comercial, disponibilidade, integração técnica e consentimento do usuário quando houver dados pessoais ou ranking.",
    "Logo Clube NSC obtido do site oficial para uso nesta proposta interna.",
  ]);
}

// 09 — Commercial inventory
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Monetização", "Uma oferta que soma mídia, benefício, dados e experiência.", "O patrocinador compra presença ao longo da jornada, com entregas e métricas que cabem no mesmo painel.", { titleSize: 40 });

  const layers = [
    { x: 72, w: 434, y: 236, t: "01  PROPRIEDADE ALWAYS-ON", d: "Naming, presença na home, agenda e quadros recorrentes.", c: C.dark, tc: C.white },
    { x: 112, w: 474, y: 314, t: "02  CONTEÚDO E SERVIÇO", d: "Radar da semana, histórias, especialistas e dados da corrida.", c: "#384044", tc: C.white },
    { x: 152, w: 514, y: 392, t: "03  BENEFÍCIO NO CLUBE", d: "Vantagem do mês, cotas de vagas e experiências exclusivas.", c: C.orange, tc: C.white },
    { x: 192, w: 554, y: 470, t: "04  EXPERIÊNCIA E EVENTO", d: "Treinos, Corrida Verde, recovery lounge e cobertura ao vivo.", c: C.yellow, tc: C.ink },
  ];
  for (const l of layers) {
    box(slide, l.x, l.y, l.w, 64, l.c, { geometry: "roundRect", radius: 16 });
    text(slide, l.t, l.x + 22, l.y + 10, l.w - 44, 21, { size: 16.5, bold: true, color: l.tc });
    text(slide, l.d, l.x + 22, l.y + 34, l.w - 44, 22, { size: 13.5, color: l.tc === C.ink ? "#554100" : "#E5E8E9" });
  }

  box(slide, 808, 226, 408, 330, C.white, { geometry: "roundRect", radius: 22, line: { style: "solid", fill: "#D8DADB", width: 1 } });
  text(slide, "PAINEL DE VALOR", 838, 252, 340, 26, { size: 17, bold: true, color: C.ink });
  const measures = [
    ["Alcance", "pessoas expostas"],
    ["Consumo", "tempo, vídeo e retorno"],
    ["Benefício", "resgates e economia"],
    ["Conversão", "leads opt-in e inscrições"],
    ["Assinatura", "aquisição e retenção"],
    ["Receita", "patrocínio e pipeline"],
  ];
  for (let i = 0; i < measures.length; i++) {
    const yy = 296 + i * 40;
    dot(slide, 838, yy + 1, 20, i < 2 ? C.cyan : i < 4 ? C.orange : C.green, "");
    text(slide, measures[i][0], 870, yy, 116, 24, { size: 16, bold: true, color: C.ink });
    text(slide, measures[i][1], 988, yy + 1, 184, 22, { size: 14, color: C.muted, align: "right" });
  }
  pill(slide, "LGPD: DADOS E SEGMENTAÇÃO SOMENTE COM CONSENTIMENTO", 808, 578, 408, "#E5F5F0", "#17684A");
  text(slide, "Categorias naturais: saúde, finanças, mobilidade, hidratação, nutrição, vestuário e turismo regional.", 72, 626, 1144, 34, { size: 15, color: C.muted, align: "center" });
  await footer(slide, 9);
  notes(slide, [
    "Proposta comercial RunnerHub. Inventário, métricas e categorias são hipóteses para desenho conjunto com editorial, comercial, produto e Clube NSC.",
    "Qualquer uso de dados pessoais, segmentação, ranking, CRM ou compartilhamento com patrocinadores deve respeitar consentimento, finalidade e governança LGPD.",
  ]);
}

// 10 — Pilot
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  titleBlock(slide, "Primeiro passo", "Piloto de 90 dias para provar valor antes de escalar.", "Um ciclo curto cria o produto mínimo, ativa o Clube NSC e mede adesão real.", { titleSize: 40 });

  const phases = [
    { x: 64, n: "0–30", t: "FUNDAR", c: C.dark, items: ["nome e identidade", "ritual editorial", "feed de calendário", "3 benefícios iniciais"] },
    { x: 442, n: "31–60", t: "ATIVAR", c: C.orange, items: ["lançamento ao público", "agenda semanal", "primeiro treino", "pacotes a marcas"] },
    { x: 820, n: "61–90", t: "PROVAR", c: C.yellow, items: ["evento âncora", "conteúdo de resultados", "dashboard do piloto", "roadmap de escala"] },
  ];
  for (let i = 0; i < phases.length; i++) {
    const p = phases[i];
    box(slide, p.x, 230, 332, 304, "#F3F4F3", { geometry: "roundRect", radius: 22, line: { style: "solid", fill: "#DCDFDF", width: 1 } });
    box(slide, p.x, 230, 332, 64, p.c, { geometry: "roundRect", radius: 22 });
    text(slide, `DIAS ${p.n}`, p.x + 22, 245, 120, 30, { size: 17, bold: true, color: p.c === C.yellow ? C.ink : C.white });
    text(slide, p.t, p.x + 160, 245, 148, 30, { size: 20, bold: true, color: p.c === C.yellow ? C.ink : C.white, align: "right" });
    for (let j = 0; j < p.items.length; j++) {
      dot(slide, p.x + 24, 326 + j * 46, 24, p.c, String(j + 1), p.c === C.yellow ? C.ink : C.white);
      text(slide, p.items[j], p.x + 60, 326 + j * 46, 236, 27, { size: 17, color: C.ink });
    }
    if (i < phases.length - 1) dot(slide, p.x + 346, 368, 20, "#D8DADB", "", C.ink);
  }

  box(slide, 144, 568, 992, 64, C.dark, { geometry: "roundRect", radius: 17 });
  text(slide, "Métricas do piloto: audiência • cadastros opt-in • resgates • conversões • pipeline comercial • sinal de assinatura", 172, 586, 936, 32, { size: 18, bold: true, color: C.white, align: "center" });
  await footer(slide, 10);
  notes(slide, [
    "Proposta operacional RunnerHub. Metas quantitativas devem ser definidas depois da linha de base dos canais NSC, do Clube NSC e do inventário de parceiros.",
    "Sugestão: usar um evento âncora já relacionado à NSC ou uma prova parceira com acesso operacional aos dados e direitos de cobertura.",
  ]);
}

// 11 — Decision
{
  const slide = presentation.slides.add();
  slide.background.fill = C.dark;
  box(slide, 0, 0, W, H, C.dark);
  box(slide, 1000, 0, 280, 72, C.orange, { geometry: "roundRect", radius: 22 });
  box(slide, 0, 648, 360, 72, C.yellow, { geometry: "roundRect", radius: 20 });
  pill(slide, "PRÓXIMO PASSO", 72, 54, 168, C.yellow, C.ink);
  text(slide, "A decisão que pedimos nesta reunião", 72, 112, 1000, 72, { size: 49, bold: true, color: C.white });
  text(slide, "Sair com um piloto patrocinado, donos claros e uma data de estreia.", 72, 188, 940, 42, { size: 22, color: C.light });

  const decisions = [
    { n: "01", t: "APROVAR O CO-DESENHO", d: "Piloto de 90 dias sob a marca NSC Corre.", c: C.yellow },
    { n: "02", t: "NOMEAR OS DONOS", d: "Editorial, comercial, produto, Clube NSC e RunnerHub.", c: C.orange },
    { n: "03", t: "ESCOLHER A ÂNCORA", d: "Um evento e três benefícios para a primeira ativação.", c: C.cyan },
  ];
  for (let i = 0; i < decisions.length; i++) {
    const x = 72 + i * 382;
    box(slide, x, 286, 342, 214, "#222426", { geometry: "roundRect", radius: 22, line: { style: "solid", fill: "#44484B", width: 1 } });
    dot(slide, x + 24, 310, 54, decisions[i].c, decisions[i].n, C.ink);
    text(slide, decisions[i].t, x + 24, 382, 294, 28, { size: 18, bold: true, color: C.white });
    text(slide, decisions[i].d, x + 24, 426, 294, 50, { size: 17, color: C.light, lineSpacing: 1.08 });
  }
  box(slide, 278, 548, 724, 70, C.white, { geometry: "roundRect", radius: 18 });
  text(slide, "Saída desejada: workshop agendado + responsáveis + data de lançamento", 306, 568, 668, 32, { size: 20, bold: true, color: C.ink, align: "center" });
  await image(slide, A.runnerDark, { left: 72, top: 660, width: 158, height: 28 }, { alt: "RunnerHub" });
  text(slide, "NSC CORRE", 1042, 660, 166, 28, { size: 17, bold: true, color: C.yellow, align: "right" });
  notes(slide, [
    "Fechamento sugerido: solicitar um workshop de 90 minutos com líderes de editorial, comercial, produto e Clube NSC para fechar o escopo do piloto.",
    "A proposta não depende de criar uma nova corrida imediatamente. Pode começar sobre um evento existente ou parceiro.",
  ]);
}

// 12 — Appendix: methodology
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Apêndice 1", "Nota metodológica: números diferentes não podem ser somados.", "Antes de comparar fontes, quatro perguntas precisam estar respondidas.", { titleSize: 38 });
  const qs = [
    { n: "1", t: "QUAL É O UNIVERSO?", d: "Permit, federação, cadastro próprio, evento mapeado ou prova com resultado publicado?", c: C.orange },
    { n: "2", t: "QUAL É O CORTE?", d: "Calendário completo, ano corrido ou posição até uma data específica?", c: C.yellow },
    { n: "3", t: "HÁ CONFIRMAÇÃO?", d: "Cadastro informa intenção. Resultado, cobertura ou evidência operacional informa execução.", c: C.cyan },
    { n: "4", t: "COMO DUPLICAÇÕES SÃO TRATADAS?", d: "Sem microdados e chave de deduplicação, diferenças não viram taxa de cobertura.", c: C.green },
  ];
  for (let i = 0; i < qs.length; i++) {
    const col = i % 2, row = Math.floor(i / 2);
    const x = 64 + col * 584, y = 222 + row * 176;
    box(slide, x, y, 552, 148, C.white, { geometry: "roundRect", radius: 20, line: { style: "solid", fill: "#D9DCDD", width: 1 } });
    dot(slide, x + 22, y + 22, 50, qs[i].c, qs[i].n, C.ink);
    text(slide, qs[i].t, x + 88, y + 22, 420, 25, { size: 17, bold: true, color: C.ink });
    text(slide, qs[i].d, x + 88, y + 58, 420, 66, { size: 16.5, color: C.muted, lineSpacing: 1.07 });
  }
  box(slide, 152, 584, 976, 56, C.dark, { geometry: "roundRect", radius: 15 });
  text(slide, "Regra editorial: publicar fonte, definição, período e limitação junto do número.", 178, 599, 924, 28, { size: 21, bold: true, color: C.white, align: "center" });
  await footer(slide, 12);
  notes(slide, [
    "Fontes: artigo Máquina do Esporte, publicação ABRACEO e base oficial RunnerHub.",
    "https://maquinadoesporte.com.br/running/corridas-de-rua-crescem-85-no-brasil-em-2025/",
    "https://abraceo.com.br/4o-summit-abraceo-cbat-corridas-de-rua-cresceram-85-em-2025-no-brasil/",
    "Não afirmar que uma fonte ‘espera passivamente’ informação de afiliados sem documentação pública. O ponto demonstrável é que universos e critérios diferem e precisam ser explicitados.",
  ]);
}

// 13 — Appendix: roles and governance
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  titleBlock(slide, "Apêndice 2", "Modelo de parceria para começar leve e preservar credibilidade.", "Papéis claros evitam retrabalho editorial, comercial e de produto.", { titleSize: 38 });

  const cols = [
    { x: 64, t: "RUNNERHUB", c: C.yellow, items: ["taxonomia e calendário", "validação e contexto", "resultados e inteligência", "painel do piloto"] },
    { x: 434, t: "NSC", c: C.orange, items: ["linha editorial", "distribuição multicanal", "venda e branded content", "produção e experiência"] },
    { x: 804, t: "EM CONJUNTO", c: C.cyan, items: ["benefícios do Clube", "pacotes a patrocinadores", "governança de marca", "roadmap e metas"] },
  ];
  for (const col of cols) {
    box(slide, col.x, 226, 348, 300, "#F2F4F4", { geometry: "roundRect", radius: 22 });
    box(slide, col.x, 226, 348, 66, col.c, { geometry: "roundRect", radius: 22 });
    text(slide, col.t, col.x + 24, 244, 300, 30, { size: 19, bold: true, color: col.c === C.yellow ? C.ink : C.white, align: "center" });
    for (let j = 0; j < col.items.length; j++) {
      dot(slide, col.x + 28, 322 + j * 48, 22, col.c, "", C.ink);
      text(slide, col.items[j], col.x + 66, 320 + j * 48, 248, 27, { size: 17, color: C.ink });
    }
  }
  pill(slide, "PROTEÇÕES", 64, 558, 120, C.dark, C.white);
  text(slide, "fonte visível • protocolo de correção • consentimento LGPD • aprovação de marcas • direitos sobre eventos e imagens", 204, 559, 948, 28, { size: 17, color: C.ink });
  box(slide, 226, 608, 828, 40, "#FFF2E9", { geometry: "roundRect", radius: 12 });
  text(slide, "Credibilidade integra o produto desde a fonte até a publicação.", 244, 618, 792, 22, { size: 18, bold: true, color: C.orange, align: "center" });
  await footer(slide, 13);
  notes(slide, [
    "Proposta de governança RunnerHub. Ajustar responsabilidades no workshop de co-desenho.",
    "Confirmar direitos de uso de marcas, eventos, imagens, resultados e bases antes do lançamento público.",
  ]);
}

// 14 — Sources
{
  const slide = presentation.slides.add();
  slide.background.fill = C.paper;
  titleBlock(slide, "Fontes", "Fontes e limites desta proposta", "Dados externos e materiais fornecidos foram mantidos separados das recomendações de parceria.", { titleSize: 38 });

  const sourceCols = [
    {
      x: 64, title: "MATERIAIS RUNNERHUB", color: C.yellow,
      rows: [
        ["Brasil que Corre — Provas 2025", "PDF fornecido pelo usuário"],
        ["Base oficial SC 2024–2026", "números fornecidos pelo usuário"],
        ["Mapear parceria RunnerHub NSC", "briefing inicial"],
        ["Apresentação anterior", "referência crítica, não template"],
      ],
    },
    {
      x: 648, title: "FONTES PÚBLICAS", color: C.orange,
      rows: [
        ["ABRACEO / CBAt", "levantamento divulgado em 2026"],
        ["Máquina do Esporte", "matéria sobre crescimento em 2025"],
        ["NSC TV e NSC Esporte", "alcance e iniciativas esportivas"],
        ["Clube NSC", "benefícios e presença em SC"],
      ],
    },
  ];
  for (const col of sourceCols) {
    box(slide, col.x, 224, 536, 310, C.white, { geometry: "roundRect", radius: 22, line: { style: "solid", fill: "#D9DCDD", width: 1 } });
    box(slide, col.x, 224, 536, 56, col.color, { geometry: "roundRect", radius: 22 });
    text(slide, col.title, col.x + 24, 239, 488, 28, { size: 18, bold: true, color: col.color === C.yellow ? C.ink : C.white, align: "center" });
    for (let i = 0; i < col.rows.length; i++) {
      const yy = 305 + i * 55;
      text(slide, col.rows[i][0], col.x + 28, yy, 300, 24, { size: 16.5, bold: true, color: C.ink });
      text(slide, col.rows[i][1], col.x + 328, yy + 1, 178, 24, { size: 13.5, color: C.muted, align: "right" });
      if (i < col.rows.length - 1) line(slide, col.x + 28, yy + 38, 480, 0, "#E2E4E4", 1);
    }
  }
  box(slide, 102, 566, 1076, 74, C.dark, { geometry: "roundRect", radius: 18 });
  text(slide, "Limite central: 478 e 559 medem universos distintos. A diferença sustenta o contexto metodológico e não permite acusar erro ou calcular cobertura.", 132, 581, 1016, 48, { size: 17.5, bold: true, color: C.white, align: "center", lineSpacing: 1.04 });
  await footer(slide, 14);
  notes(slide, [
    "Materiais locais:",
    "/Users/leonardosobral/Downloads/BrasilQueCorreProvas2025_v3.10.3 (1).pdf",
    "/Users/leonardosobral/Downloads/Mapear parceria RunnerHub NSC.pdf",
    "/Users/leonardosobral/Downloads/Apresentacao_Parceria_RunnerHub_NSC.pptx.pdf",
    "Fontes públicas:",
    "https://maquinadoesporte.com.br/running/corridas-de-rua-crescem-85-no-brasil-em-2025/",
    "https://abraceo.com.br/4o-summit-abraceo-cbat-corridas-de-rua-cresceram-85-em-2025-no-brasil/",
    "https://nsc.com.br/marcas-nsc/nsc-tv/",
    "https://nsc.com.br/imprensa/nsc-esporte-amplia-presenca-digital-com-novos-canais-de-conteudo-esportivo/",
    "https://nsc.com.br/imprensa/corrida-verde-chega-a-joinville-com-experiencia-completa-para-toda-a-familia/",
    "https://nsc.com.br/imprensa/nsc-esporte-amplia-cobertura-e-participacao-na-24a-edicao-do-ironman/",
    "https://clubensc.com.br/",
    "https://clubensc.com.br/sobre-o-clube/",
  ]);
}

await (await PresentationFile.exportPptx(presentation)).save(CANDIDATE_PPTX);

const result = await finalizePresentation({
  explicitTotalSlideCount: 14,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [2, 5],
  requiredEmbeddedWorkbookChartOwnerSlides: [],
  materializeLiteralChartWorkbooks: true,
  nativeChartTargetApplication: "portable",
  workspaceDir: WORKSPACE,
  candidatePath: CANDIDATE_PPTX,
  finalPath: FINAL_PPTX,
  pythonExecutable: RUNTIME_PYTHON,
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", "12192000,6858000",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  fontPolicy: { basis: "design", families: [FONT] },
  verifyArtifactToolImport: true,
  receiptPath: RECEIPT,
});

console.log(JSON.stringify({ finalPath: FINAL_PPTX, candidatePath: CANDIDATE_PPTX, result }, null, 2));
