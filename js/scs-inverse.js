var distributionUpdated, setToDefaults, setup;
var __hasProp = Object.prototype.hasOwnProperty;
defaults['subsidy'] = null;
defaults["energy_delivered"] = {
  distribution: 'fixed',
  "value": 20
};
distributionUpdated = function() {
  var worker;
  stop();
  worker = new Worker('../js/inverse-calculation.js');
  worker.onmessage = function(event) {
    var chart, name, _results;
    _results = [];
    for (name in charts) {
      if (!__hasProp.call(charts, name)) continue;
      chart = charts[name];
      _results.push(chart.showMedianForDatum(event.data));
    }
    return _results;
  };
  return worker.postMessage({
    starting_id: 1,
    number_of_iterations: 1,
    distributions: medians()
  });
};
setToDefaults = function() {
  var chart, name, values, _results;
  _results = [];
  for (name in defaults) {
    if (!__hasProp.call(defaults, name)) continue;
    values = defaults[name];
    chart = charts[name];
    _results.push(values != null ? chart != null ? (values.distribution === "normal" ? (chart.opts.mean = values.mean, chart.showMedianForValue(chart.opts.mean)) : values.distribution === "fixed" ? (chart.opts.mean = values.value, chart.showMedianForValue(chart.opts.mean)) : void 0, chart.drawDistributionLine(), chart.allow_distribution_to_be_altered()) : void 0 : void 0);
  }
  return _results;
};
setup = function() {
  var charts;
  charts = setupCharts(slider);
  setToDefaults();
  slider.prototype.distributionUpdated = distributionUpdated;
  return d3.select("#calculate").on('click', function() {
    distributionUpdated();
    return false;
  });
};