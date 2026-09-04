const test = require("node:test");
const assert = require("node:assert/strict");

let performanceDashboard = {};

try {
    performanceDashboard = require("../../assets/js/ads-performance-dashboard.js");
} catch (error) {
    performanceDashboard = {};
}

test("summarizes impressions, clicks, CTR, investment and actual CPC", () => {
    const rows = [
        { date: "2026-09-01", impressions: 100, clicks: 4, billableClicks: 3, cost: 2.82 },
        { date: "2026-09-02", impressions: 200, clicks: 6, billableClicks: 5, cost: 4.70 }
    ];

    assert.deepEqual(
        performanceDashboard.summarize(rows),
        {
            impressions: 300,
            clicks: 10,
            billableClicks: 8,
            cost: 7.52,
            ctr: 3.3333333333333335,
            averageCpc: 0.94
        }
    );
});

test("keeps rates and costs at zero when there is no delivery", () => {
    assert.deepEqual(
        performanceDashboard.summarize([
            { date: "2026-09-02", impressions: 0, clicks: 0, billableClicks: 0, cost: 0 }
        ]),
        {
            impressions: 0,
            clicks: 0,
            billableClicks: 0,
            cost: 0,
            ctr: 0,
            averageCpc: 0
        }
    );
});

test("compares the selected period with the immediately previous period", () => {
    assert.equal(performanceDashboard.percentageChange(120, 100), 20);
    assert.equal(performanceDashboard.percentageChange(0, 10), -100);
    assert.equal(performanceDashboard.percentageChange(10, 0), 100);
    assert.equal(performanceDashboard.percentageChange(0, 0), 0);
});

test("builds a daily chart with independent traffic and currency axes", () => {
    const config = performanceDashboard.buildChartConfig([
        { date: "2026-09-01", impressions: 100, clicks: 4, billableClicks: 3, cost: 2.82 },
        { date: "2026-09-02", impressions: 200, clicks: 6, billableClicks: 5, cost: 4.70 }
    ]);

    assert.deepEqual(config.data.labels, ["01/09", "02/09"]);
    assert.deepEqual(
        config.data.datasets.map((dataset) => ({
            label: dataset.label,
            data: dataset.data,
            yAxisID: dataset.yAxisID
        })),
        [
            { label: "Impressões", data: [100, 200], yAxisID: "traffic" },
            { label: "Cliques", data: [4, 6], yAxisID: "traffic" },
            { label: "Investimento", data: [2.82, 4.7], yAxisID: "money" }
        ]
    );
    assert.equal(config.options.scales.y.display, false);
});

test("adapts the chart configuration to the MDB chart constructor", () => {
    const config = performanceDashboard.buildChartConfig([
        { date: "2026-09-02", impressions: 200, clicks: 6, billableClicks: 5, cost: 4.70 }
    ]);

    assert.deepEqual(
        performanceDashboard.toMdbChartArguments(config),
        [
            { type: "bar", data: config.data },
            config.options
        ]
    );
});
