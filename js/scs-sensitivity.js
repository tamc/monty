var charts, iteration, running, setup, worker;
charts = {};
iteration = [];
running = false;
worker = null;
setup = function() {
  charts = setupCharts(slider);
  setToDefaults();
  slider.prototype.distributionUpdated = distributionUpdated;
  return distributionUpdated();
};