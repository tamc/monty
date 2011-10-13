histogram.defaults =
  tag:      "body"
  width:    250
  height:   125
  padding:  35
  x_min:    0
  x_max:    300
  y_min:    0
  y_max:    20
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
  width:    500
  height:   500
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

defaults = { 
  "subsidy": {distribution: 'fixed', "value": 94 }
  "capital_cost":{distribution: 'normal', "mean":2211,"sd":(2211-1756)},
  "operating_cost":{distribution: 'normal', "mean":132,"sd":(132-81)/2},
  "fuel_cost": {distribution: 'fixed', "value": 0 }
  "efficiency": {distribution: 'fixed', "value": 100 }
  "availability": {distribution: 'normal', "mean":30,"sd":7},
  "economic_life":{distribution: 'normal', "mean":25,"sd":7},
  "hurdle_rate":{distribution: 'normal', "mean":13,"sd":2},
  "capital_available":{distribution: 'normal', "mean":17,"sd":5},
  "price":{distribution: 'normal', "mean":71,"sd":(71-41)/3}
}

charts = {}
iterations = []
running = false
worker = null

setup = () ->
    # Create the charts
    charts['capital_cost'] = new histogram(tag:'#capital', x_axis_title:"Capital cost (£/kW)", x_max: 7500, property: (d) -> d.capital_cost)
    charts['operating_cost'] = new histogram(tag:"#operating", x_axis_title:"Operating cost (£/kW/yr)", property: (d) -> d.operating_cost)
#    charts['fuel_cost'] = new histogram(tag:"#fuel",x_axis_title:"Fuel cost (£/MWh)", property: (d) -> d.fuel_cost)
    charts['availability'] = new histogram(tag:"#availability", x_axis_title:"Capacity factor (% of peak output that are actually delivered)", x_axis_suffix:"%", x_max: 100,property:(d) -> d.availability)
    charts['economic_life'] = new histogram(tag:"#life", x_axis_title:"Economic life (years)", x_max: 100, property:(d) -> d.economic_life)
    charts['hurdle_rate'] = new histogram(tag:"#hurdle", x_axis_title:"Investor's hurdle rate (apr)", x_axis_suffix: "%", x_max: 20, property:(d) -> d.hurdle_rate)
    charts['capital_available'] = new histogram(tag: "#quantity", x_axis_title:"Investor's capital available £bn", x_max: 50, property:(d) -> d.capital_available)
    charts['price'] = new histogram(tag: "#price", x_axis_title:"Price of electricity £/MWh", property:(d) -> d.price)   
    charts['energy_delivered'] = new histogram(tag: "#energyDelivered", x_axis_title: "Energy delivered TWh", x_max:70, width: 500, height: 250,  property: (d) -> d.energyDelivered)
    charts['public_spend'] = new histogram(tag: "#publicSpend", x_axis_title: "Public expenditure £bn", x_max: 7, width: 500, height: 250, property: (d) -> d.publicSpend)
    
    charts['public_spend_against_energy'] = new scatterplot(tag: '#spendEnergyDelivered', x_axis_title: "Public expenditure £bn", y_axis_title: "Energy delivered TWh", x_max: 10, y_max: 100, x_property: ((d) -> d.publicSpend), y_property: ((d) -> d.energyDelivered))
      
    # Set up the controls
    d3.select("#oneRun").on('click',() -> start(1); return false)
    d3.select("#tenRuns").on('click',() -> start(10); return false)
    d3.select("#hundredRuns").on('click',() -> start(100); return false)
    d3.select("#fiveHundredRuns").on('click',() -> start(500); return false)
    d3.select("#stopButton").on('click',() -> stop(); return false)
    d3.select("#clearButton").on('click',() -> clear(); return false)
    d3.select("#defaultsButton").on('click',() -> clear(); setToDefaults(); return false)
    d3.select("#toggleDistributions").on('click',() -> clear(); toggleDistributions(); return false)

    setToDefaults()
    
    # Set up the green lines to indicate calculated median
    histogram.prototype.distributionUpdated = distributionUpdated
    
    distributionUpdated()
    
    
distributionUpdated = () ->
  stop()
  worker = new Worker('../js/calculation.js')
  worker.onmessage = (event) ->
    console.log event.data
    for own name, chart of charts  
      chart.showMedianForDatum(event.data)
  worker.postMessage(starting_id: 1, number_of_iterations: 1, distributions: medians());
    
setToDefaults = () ->
  # Set default distributions for the charts
  for own name, values of defaults
    chart = charts[name]
    if chart?
      chart.opts.mean = values.mean
      chart.opts.standard_deviation = values.sd
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
    else
      parameters[name] = defaultDistribution
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
