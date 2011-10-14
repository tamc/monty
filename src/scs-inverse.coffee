defaults['subsidy'] = null
defaults["energy_delivered"] = {distribution: 'fixed', "value": 20}
defaults["total_profit"] = {distribution: 'fixed', "value": 0}

distributionUpdated = () ->
  stop()
  worker = new Worker('../js/inverse-calculation.js')
  worker.onmessage = (event) ->
    for own name, chart of charts  
      chart.showMedianForDatum(event.data)
  worker.postMessage(starting_id: 1, number_of_iterations: 1, distributions: medians());

setToDefaults = () ->
  # Set default distributions for the charts
  for own name, values of defaults
    chart = charts[name]
    if values?
      if chart?
        if values.distribution == "normal"
          chart.opts.mean = values.mean
          #chart.opts.standard_deviation = values.sd
          chart.showMedianForValue(chart.opts.mean)
        else if values.distribution == "fixed"
          chart.opts.mean = values.value
          chart.showMedianForValue(chart.opts.mean)
        chart.drawDistributionLine()
        chart.allow_distribution_to_be_altered()

setup = () ->
  charts = setupCharts(slider)
  setToDefaults()
  slider.prototype.distributionUpdated = distributionUpdated
  d3.select("#calculate").on('click',() -> distributionUpdated(); return false)
  

