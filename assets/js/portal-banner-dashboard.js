(function (root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory(require('./ads-performance-dashboard.js'));
    } else {
        root.BannerPerformanceDashboard = factory(root.AdsPerformanceDashboard);
    }
})(typeof globalThis !== 'undefined' ? globalThis : this, function (ads) {
    'use strict';
    return {
        buildChartConfig: function (rows) {
            const config = ads.buildChartConfig(rows);
            config.data.datasets = config.data.datasets.filter(function (dataset) { return dataset.yAxisID !== 'money'; });
            delete config.options.scales.money;
            return config;
        }
    };
});
