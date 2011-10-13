var setup;
setup = function() {
  var charts;
  charts = setupCharts(histogram);
  d3.select("#oneRun").on('click', function() {
    start(1);
    return false;
  });
  d3.select("#tenRuns").on('click', function() {
    start(10);
    return false;
  });
  d3.select("#hundredRuns").on('click', function() {
    start(100);
    return false;
  });
  d3.select("#fiveHundredRuns").on('click', function() {
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