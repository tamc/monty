charts = {}
iteration = []
running = false
worker = null

setup = () ->
  charts = setupCharts(slider)
  setToDefaults()
  slider.prototype.distributionUpdated = distributionUpdated
  distributionUpdated()