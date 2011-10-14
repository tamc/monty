histogram.defaults =
  tag:      "body"
  width:    350
  height:   180
  padding:  35
  x_min:    0
  x_max:    300
  y_min:    0
  y_max:    25
  x_ticks:  10
  y_ticks:  5
  property: (d) -> d
  attempts: 500
  bins:     50
  title:    null
  x_axis_suffix: ""
  x_axis_title: null 
  y_axis_suffix: "%"
  y_axis_title: ""

scatterplot.defaults =
  tag:      "body"
  width:    350
  height:   350
  padding:  35
  x_min:    0
  x_max:    300
  y_min:    0
  y_max:    10
  x_ticks:  10
  y_ticks:  10
  x_property: (d) -> d
  y_property: (d) -> d  
  title:    null
  x_axis_suffix: ""
  x_axis_title: null 
  y_axis_suffix: ""
  y_axis_title: null

slider.defaults =
  tag:      "body"
  width:    350
  height:   180
  padding:  35
  x_min:    0
  x_max:    300
  y_min:    0
  x_ticks:  10
  property: (d) -> d
  attempts: 500
  bins:     50
  title:    null
  x_axis_suffix: ""
  x_axis_title: null

defaults = { 
  "subsidy": {distribution: 'fixed', "value": 94 }
  "capital_cost":{distribution: 'normal', "mean":2211,"sd":(2211-1756)},
  "operating_cost":{distribution: 'normal', "mean":132,"sd":(132-81)/2},
  "fuel_cost": {distribution: 'fixed', "value": 0 }
  "efficiency": {distribution: 'fixed', "value": 100 }
  "availability": {distribution: 'normal', "mean":30,"sd":4},
  "economic_life":{distribution: 'normal', "mean":25,"sd":4},
  "hurdle_rate":{distribution: 'normal', "mean":13,"sd":2},
  "capital_available":{distribution: 'normal', "mean":17,"sd":2},
  "price":{distribution: 'normal', "mean":71,"sd":(71-41)/3}
  "capital_falloff":{distribution: 'normal', 'mean':(17/4),"sd":1}
  "capital_rampup":{distribution: 'normal', 'mean':(5/20),"sd":1}
}

charts = {}
iterations = []
running = false
worker = null

distributionUpdated = () ->
  stop()
  worker = new Worker('../js/calculation.js')
  worker.onmessage = (event) ->
    # console.log JSON.stringify(event.data)
    for own name, chart of charts  
      chart.showMedianForDatum(event.data)
  worker.postMessage(starting_id: 1, number_of_iterations: 1, distributions: medians());
    
setToDefaults = () ->
  # Set default distributions for the charts
  for own name, values of defaults
    if values?
      chart = charts[name]
      if chart?
        if values.distribution == "normal"
          chart.opts.mean = values.mean
          chart.opts.standard_deviation = values.sd
        else if values.distribution == "fixed"
          chart.opts.mean = values.value
        chart.drawDistributionLine()
        chart.allow_distribution_to_be_altered()

toggleDistributions = () ->
  for own name, chart of charts
    if chart.toggleDistributions?
      chart.toggleDistributions()

medians = () ->
  parameters = {}
  for own name, defaultDistribution of defaults
    chart = charts[name]
    if chart?
      parameters[name] = { distribution: 'fixed', value: chart.opts.mean }
    else if defaultDistribution.value?
      parameters[name] = { distribution: 'fixed', value: defaultDistribution.value }
    else if defaultDistribution.mean?
      parameters[name] = { distribution: 'fixed', value: defaultDistribution.mean }
  parameters

distributions = () ->
  parameters = {}
  for own name, defaultDistribution of defaults
    chart = charts[name]
    if chart?
      parameters[name] = chart.distribution()
    else
      parameters[name] = defaultDistribution
  console.log parameters
  parameters
    
stop = () ->
  return unless running == true
  running = false
  worker.terminate()

start = (number_of_iterations = 500) ->  
  stop()
  d3.selectAll("rect.selected").classed('selected',false)
  worker = new Worker('../js/calculation.js')
  running = true
  worker.onmessage = (event) ->
    iterations.push(event.data)
    for own name, chart of charts
      chart.update(iterations) 
    d3.select("#message}").text("#{iterations.length} runs completed")
  worker.onerror = (error) ->  
    console.log("Calculation error: " + error.message + "\n")
    throw error
  worker.postMessage(starting_id: iterations.length, number_of_iterations: number_of_iterations, distributions: distributions());

clear = () ->
  stop()
  iterations = []
  chart.clear() for own name,chart of charts
  d3.select("#message}").text("")
  
setupCharts = (constructor) ->
  charts = {}
  
  # Income
  charts['subsidy'] = new constructor(tag:'#subsidy', x_axis_title:"Level of subsidy £/MWh", x_max: 200, property: (d) -> d.subsidy)
  charts['price'] = new constructor(tag: "#price", x_axis_title:"Price of electricity £/MWh", property:(d) -> d.price)  

  # Expense
  charts['capital_cost'] = new constructor(tag:'#capital', x_axis_title:"Capital cost £/kW", x_max: 7500, property: (d) -> d.capital_cost)
  charts['operating_cost'] = new constructor(tag:"#operating", x_axis_title:"Operating cost £/kW/yr", property: (d) -> d.operating_cost)
  charts['availability'] = new constructor(tag:"#availability", x_axis_title:"Average output, % of peak", x_axis_suffix:"%", x_max: 100,property:(d) -> d.availability)
  
  # Investment
  charts['economic_life'] = new constructor(tag:"#life", x_axis_title:"Economic life, years", x_max: 100, property:(d) -> d.economic_life)
  charts['hurdle_rate'] = new constructor(tag:"#hurdle", x_axis_title:"Investor's hurdle rate, %", x_axis_suffix: "%", x_max: 20, property:(d) -> d.hurdle_rate)
  charts['capital_available'] = new constructor(tag: "#quantity", x_axis_title:"Capital available at hurdle rate £bn", x_max: 50, property:(d) -> d.capital_available)
  charts['capital_falloff'] = new constructor(tag: "#falloff", x_axis_title:"Fall in capital per pp fall in IRR, £bn", x_max: 10, property:(d) -> d.capital_falloff)
  charts['capital_rampup'] = new constructor(tag: "#rampup", x_axis_title:"Increase in capital per pp increase in IRR, £bn", x_max: 10, property:(d) -> d.capital_rampup)
  
  # Results 
  charts['energy_delivered'] = new constructor(tag: "#energyDelivered", x_axis_title: "Energy delivered TWh", x_max:70,  property: (d) -> d.energy_delivered)
  charts['public_spend'] = new constructor(tag: "#publicSpend", x_axis_title: "Public expenditure £bn", x_max: 7, property: (d) -> d.public_spend)
  charts['total_profit'] = new constructor(tag: "#totalProfit", x_axis_title: "Private 'excess' profit £bn", x_max: 7, property: (d) -> d.total_profit)

  charts['internal_rate_of_return'] = new constructor(tag: "#irr", x_axis_title: "IRR", x_max: 100, property: (d) -> d.internal_rate_of_return)

  charts