var setNumberOfAttempts, setup;
var __hasProp = Object.prototype.hasOwnProperty;
setNumberOfAttempts = function(attempts) {
  var chart, name, _results;
  _results = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    _results.push(chart.setBlockHeight != null ? chart.setBlockHeight(attempts) : void 0);
  }
  return _results;
};
setup = function() {
  var charts;
  charts = setupCharts(histogram);
  d3.select("#oneRun").on('click', function() {
    start(1);
    return false;
  });
  d3.select("#tenRuns").on('click', function() {
    clear();
    setNumberOfAttempts(10);
    start(10);
    return false;
  });
  d3.select("#hundredRuns").on('click', function() {
    clear();
    setNumberOfAttempts(100);
    start(100);
    return false;
  });
  d3.select("#fiveHundredRuns").on('click', function() {
    clear();
    setNumberOfAttempts(500);
    start(500);
    return false;
  });
  d3.select("#stopButton").on('click', function() {
    stop();
    return false;
  });
  d3.select("#clearButton").on('click', function() {
    clear();
    return false;
  });
  d3.select("#defaultsButton").on('click', function() {
    clear();
    setToDefaults();
    return false;
  });
  d3.select("#toggleDistributions").on('click', function() {
    clear();
    toggleDistributions();
    return false;
  });
  setToDefaults();
  histogram.prototype.distributionUpdated = distributionUpdated;
  return distributionUpdated();
};