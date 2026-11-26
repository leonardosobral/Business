const panel = document.querySelector("[data-challenge-daily-stats]");
const charts = panel?.querySelectorAll("[data-challenge-daily-chart]");

if (charts?.length) {
    const rows = Array.from(panel.querySelectorAll("[data-challenge-date]"));
    const column = (index) => rows.map((row) => Number(row.cells[index].textContent.trim()));
    const labels = rows.map((row) => row.dataset.challengeDate.slice(5).split("-").reverse().join("/"));
    const fullDates = rows.map((row) => row.cells[0].textContent.trim());
    const colors = getComputedStyle(panel);
    const accent = colors.getPropertyValue("--business-accent").trim() || "#f4b120";
    const muted = colors.getPropertyValue("--business-muted").trim() || "#bdbdbd";
    const datasets = {
        registrations: { label: "Inscrições", data: column(1), backgroundColor: "#d9d9d9", borderRadius: 3 },
        activities: { label: "Atividades registradas", data: column(2), backgroundColor: accent, borderRadius: 3 }
    };

    try {
        const { Chart } = await import("/assets/js/chart.es.min.js");
        for (const canvas of charts) {
            new Chart(canvas, {
                type: "bar",
                data: { labels, datasets: [datasets[canvas.dataset.challengeDailyChart]] }
            }, {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: "index", intersect: false },
                plugins: {
                    legend: { display: false },
                    tooltip: { callbacks: { title: (points) => fullDates[points[0].dataIndex] } }
                },
                scales: {
                    x: { grid: { display: false }, ticks: { color: muted, maxRotation: 0, maxTicksLimit: 12 } },
                    y: { beginAtZero: true, grid: { color: "rgba(255,255,255,.1)" }, ticks: { color: muted, precision: 0 } }
                }
            });
            canvas.dataset.ready = "true";
        }
    } catch (error) {
        panel.querySelector("[data-challenge-chart-area]").hidden = true;
        panel.querySelector("details").open = true;
        console.error("Não foi possível montar o gráfico diário do desafio.", error);
    }
}
