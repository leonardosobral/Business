(function (root, factory) {
    const dashboard = factory();

    if (typeof module === "object" && module.exports) {
        module.exports = dashboard;
    } else {
        root.AdsPerformanceDashboard = dashboard;
    }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
    "use strict";

    function number(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : 0;
    }

    function summarize(rows) {
        const totals = (Array.isArray(rows) ? rows : []).reduce(function (summary, row) {
            summary.impressions += number(row.impressions);
            summary.clicks += number(row.clicks);
            summary.billableClicks += number(row.billableClicks);
            summary.cost += number(row.cost);
            return summary;
        }, { impressions: 0, clicks: 0, billableClicks: 0, cost: 0 });

        totals.cost = Math.round((totals.cost + Number.EPSILON) * 100) / 100;
        totals.ctr = totals.impressions > 0 ? totals.clicks * 100 / totals.impressions : 0;
        totals.averageCpc = totals.billableClicks > 0 ? totals.cost / totals.billableClicks : 0;
        return totals;
    }

    function percentageChange(current, previous) {
        const currentValue = number(current);
        const previousValue = number(previous);
        if (previousValue === 0) return currentValue === 0 ? 0 : 100;
        return (currentValue - previousValue) * 100 / previousValue;
    }

    function shortDate(value) {
        const parts = String(value || "").split("-");
        return parts.length === 3 ? parts[2] + "/" + parts[1] : String(value || "");
    }

    function buildChartConfig(rows) {
        const safeRows = Array.isArray(rows) ? rows : [];
        return {
            type: "bar",
            data: {
                labels: safeRows.map(function (row) { return shortDate(row.date); }),
                datasets: [
                    {
                        label: "Impressões",
                        data: safeRows.map(function (row) { return number(row.impressions); }),
                        yAxisID: "traffic",
                        backgroundColor: "rgba(98, 199, 216, .48)",
                        borderColor: "#62c7d8",
                        borderWidth: 1,
                        borderRadius: 3
                    },
                    {
                        label: "Cliques",
                        data: safeRows.map(function (row) { return number(row.clicks); }),
                        yAxisID: "traffic",
                        type: "line",
                        borderColor: "#f4b120",
                        backgroundColor: "#f4b120",
                        borderWidth: 3,
                        pointRadius: 3,
                        pointHoverRadius: 5,
                        tension: 0.25
                    },
                    {
                        label: "Investimento",
                        data: safeRows.map(function (row) { return number(row.cost); }),
                        yAxisID: "money",
                        type: "line",
                        borderColor: "#36b779",
                        backgroundColor: "#36b779",
                        borderDash: [5, 4],
                        borderWidth: 2,
                        pointRadius: 2,
                        tension: 0.25
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: "index", intersect: false },
                plugins: {
                    legend: {
                        labels: { color: "#d9d9d9", usePointStyle: true }
                    },
                    tooltip: {
                        callbacks: {
                            label: function (context) {
                                if (context.dataset.yAxisID === "money") {
                                    return context.dataset.label + ": " + number(context.parsed.y).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
                                }
                                return context.dataset.label + ": " + number(context.parsed.y).toLocaleString("pt-BR");
                            }
                        }
                    }
                },
                scales: {
                    y: { display: false },
                    x: {
                        grid: { display: false },
                        ticks: { color: "#a9a9a9", maxRotation: 0, autoSkip: true, maxTicksLimit: 10 }
                    },
                    traffic: {
                        beginAtZero: true,
                        position: "left",
                        grid: { color: "rgba(255,255,255,.07)" },
                        ticks: { color: "#a9a9a9", precision: 0 }
                    },
                    money: {
                        beginAtZero: true,
                        position: "right",
                        grid: { drawOnChartArea: false },
                        ticks: {
                            color: "#73c99b",
                            callback: function (value) {
                                return number(value).toLocaleString("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
                            }
                        }
                    }
                }
            }
        };
    }

    function toMdbChartArguments(config) {
        return [
            { type: config.type, data: config.data },
            config.options
        ];
    }

    return {
        summarize: summarize,
        percentageChange: percentageChange,
        buildChartConfig: buildChartConfig,
        toMdbChartArguments: toMdbChartArguments
    };
});
