histogram.defaults =
  tag:      "body"
  width:    250
  height:   250
  padding:  35
  x_min:    0
  x_max:    300
  y_min:    0
  y_max:    20
  x_ticks:  10
  y_ticks:  10
  property: (d) -> d
  attempts: 500
  bins:     50
  title:    null
  x_axis_suffix: ""
  x_axis_title: null 
  y_axis_suffix: "%"
  y_axis_title: "Proportion over 500 attempts"

scatterplot.defaults =
  tag:      "body"
  width:    250
  height:   250
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
  "subsidy": {distribution: 'normal', "mean":100,"sd":0}
  "capital_cost":{distribution: 'normal', "mean":3700,"sd":(3700-2900)},
  "operating_cost":{distribution: 'normal', "mean":78,"sd":(78-64)},
  "fuel_cost":{distribution: 'normal', "mean":0,"sd":0},
  "efficiency":{distribution: 'normal', "mean":95,"sd":2},
  "availability":{distribution: 'normal', "mean":86,"sd":4},
  "economic_life":{distribution: 'normal', "mean":60,"sd":10},
  "hurdle_rate":{distribution: 'normal', "mean":10,"sd":3},
  "capital_available":{distribution: 'normal', "mean":5,"sd":1},
  "price":{distribution: 'normal', "mean":50,"sd":10}
}

charts = {}
iterations = []
running = false
worker = null

setup = () ->
    # Create the charts
    charts['subsidy'] = new histogram(tag:'#subsidy', x_axis_title:"Subsidy (£/MWh)", x_max: 400, property: (d) -> d.subsidy)
    charts['capital_cost'] = new histogram(tag:'#capital', x_axis_title:"Capital cost (£/kW)", x_max: 7500, property: (d) -> d.capital_cost)
    charts['operating_cost'] = new histogram(tag:"#operating", x_axis_title:"Operating cost (£/kW/yr)", property: (d) -> d.operating_cost)
#    charts['fuel_cost'] = new histogram(tag:"#fuel",x_axis_title:"Fuel cost (£/MWh)", property: (d) -> d.fuel_cost)
    charts['efficiency'] = new histogram(tag:"#efficiency", x_axis_title:"Efficiency", x_axis_suffix: "%", x_max: 100, property:(d) -> d.efficiency)
    charts['availability'] = new histogram(tag:"#availability", x_axis_title:"Availability or capacity factor (% of hours operating)", x_axis_suffix:"%", x_max: 100,property:(d) -> d.availability)
    charts['economic_life'] = new histogram(tag:"#life", x_axis_title:"Economic life (years)", x_max: 100, property:(d) -> d.economic_life)
    charts['hurdle_rate'] = new histogram(tag:"#hurdle", x_axis_title:"Investor's hurdle rate (apr)", x_axis_suffix: "%", x_max: 20, property:(d) -> d.hurdle_rate)
    charts['capital_available'] = new histogram(tag: "#quantity", x_axis_title:"Investor's capital available £bn", x_max: 10, property:(d) -> d.capital_available)
    charts['cost_per_MWh'] = new histogram(tag: "#annualcost", x_axis_title:"Cost £/MWh", x_max: 300, property:(d) -> d.cost_per_MWh)
    charts['price'] = new histogram(tag: "#price", x_axis_title:"Price of electricity £/MWh", property:(d) -> d.price)   
    charts['deployment'] = new histogram(tag: "#deployment", x_axis_title: "Quantity deployed MW", x_max: 3000, property: (d) -> d.deployment)
    charts['energy_delivered'] = new histogram(tag: "#energyDelivered", x_axis_title: "Energy delivered TWh", x_max:50, property: (d) -> d.energyDelivered)
    charts['public_spend'] = new histogram(tag: "#publicSpend", x_axis_title: "Public expenditure £bn", x_max: 5, property: (d) -> d.publicSpend)
    charts['public_spend_against_energy'] = new scatterplot(tag: '#spendEnergyDelivered', x_axis_title: "Public expenditure £bn", y_axis_title: "Energy delivered TWh", x_max: 5, y_max: 50, x_property: ((d) -> d.publicSpend), y_property: ((d) -> d.energyDelivered))
    charts['energy_per_public_spend_against_public_spend'] = new scatterplot(tag:'#energyPerPoundAgainstPounds', x_axis_title:"Public expenditure £", y_axis_title:"Energy per pound of public spend MWh/£", x_max:5, y_max: 20, x_property:((d) -> d.publicSpend), y_property:((d) -> (d.energyDelivered / d.publicSpend)))
      
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
  