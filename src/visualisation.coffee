normalZ = (x,mean,standard_deviation) ->
  a = x - mean;
  Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation); 

# Lifted from https://github.com/jstat/jstat/blob/master/src/core.js
erf = ( x ) ->
	cof = [
		-1.3026537197817094, 6.4196979235649026e-1, 1.9476473204185836e-2,
		-9.561514786808631e-3, -9.46595344482036e-4, 3.66839497852761e-4,
		4.2523324806907e-5, -2.0278578112534e-5, -1.624290004647e-6,
		1.303655835580e-6, 1.5626441722e-8, -8.5238095915e-8,
		6.529054439e-9, 5.059343495e-9, -9.91364156e-10,
		-2.27365122e-10, 9.6467911e-11, 2.394038e-12,
		-6.886027e-12, 8.94487e-13, 3.13092e-13,
		-1.12708e-13, 3.81e-16, 7.106e-15,
		-1.523e-15, -9.4e-17, 1.21e-16,
		-2.8e-17
		]		
	j = cof.length - 1
	isneg = false
	d = 0
	dd = 0

	if x < 0
		x = -x
		isneg = true

	t = 2 / ( 2 + x )
	ty = 4 * t - 2
	while j > 0
		tmp = d
		d = ty * d - dd + cof[j]
		dd = tmp
		j--
	res = t * Math.exp( -x*x + 0.5 * ( cof[0] + ty * d ) - dd )
	if isneg
	  return res - 1
	else
	  return 1 - res

cumulativeNormal = (x,mean,standard_deviation) ->
  0.5 * (1+erf((x-mean)/(Math.sqrt(2)*standard_deviation)))

probability_in_bin = (bin,mean,standard_deviation,bin_width) ->
  cumulativeNormal(bin+(bin_width/2),mean,standard_deviation) - cumulativeNormal(bin-(bin_width/2),mean,standard_deviation)
  
inverse_probability_in_mean_bin = (probability, mean, bin_width, guess_step = bin_width, standard_deviation_guess = 0.0) ->
  while probability_in_bin(mean,mean,standard_deviation_guess,bin_width) > probability
    standard_deviation_guess = standard_deviation_guess + guess_step
  
  error = probability - probability_in_bin(mean,mean,standard_deviation_guess,bin_width)

  if error > 0.001
    return inverse_probability_in_mean_bin(probability,mean,bin_width, guess_step / 10, standard_deviation_guess - guess_step)
  else
    return standard_deviation_guess  
  

# Drawing a histogram
histogram = (@opts = {}) ->
  # Set default options
  for own key, value of histogram.defaults
    @opts[key] = value unless @opts[key]?
  
  # Urgh. Sometimes I don't get Javascript
  that = this
  
  # Set up scales
  x = d3.scale.linear().domain([@opts.x_min,@opts.x_max]).range([0, @opts.width])
  y = d3.scale.linear().domain([@opts.y_min,@opts.y_max]).range([@opts.height, 0])
  
  # Set up bucket size and corresponding block dimenions
  x_step = (x.domain()[1] - x.domain()[0])/@opts.bins
  nesting_operator = d3.nest().key((d) -> Math.round(that.opts.property(d) / x_step) * x_step )
  block_width = x(x_step) - x(0)
  block_height = @opts.height / ((@opts.y_max / 100)*500)
  
  # Start the drawing by setting up the surround
  tag = d3.select(@opts.tag)
  tag.append("h2").text(@opts.title) if @opts.title?
  
  # Add a transformation box so we leave space around the edges for axis
  svg = tag.append("svg:svg")
      .attr("width", @opts.width + @opts.padding * 2)
      .attr("height", @opts.height + @opts.padding * 2)
    .append("svg:g")
      .attr("class","main")
      .attr("transform", "translate(" + @opts.padding + "," + @opts.padding + ")")
  
  # This captures clicks
  click_rect = svg.append("svg:rect")
    .attr("class","click")
    .attr("x", 0 )
    .attr("y", 0 )
    .attr("width", @opts.width )
    .attr("height", @opts.height)
  
  # x-axis groups
  xrule = svg.selectAll("g.x")
      .data(x.ticks(@opts.x_ticks))
    .enter().append("svg:g")
      .attr("class", "x");

  # vertical lines on chart
  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", @opts.height);
  
  # x-axis labels
  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", @opts.height + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text( (d) -> x.tickFormat(that.opts.x_ticks)(d)+that.opts.x_axis_suffix );
  
  # x-axis title
  if @opts.x_axis_title?    
    svg.append("svg:text")
      .attr("x",@opts.width/2)
      .attr("y", @opts.height + 18)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(@opts.x_axis_title)
  
  # y-axis groups
  yrule = svg.selectAll("g.y")
      .data(y.ticks(@opts.y_ticks))
    .enter().append("svg:g")
      .attr("class", "y");
  
  # horizontal lines
  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", @opts.width)
      .attr("y1", y)
      .attr("y2", y);
  
  # y-axis labels
  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text( (d) -> y.tickFormat(that.opts.y_ticks)(d)+that.opts.y_axis_suffix );
  
  # optional y-axis titles
  if @opts.y_axis_title?
    svg.append("svg:text")
      .attr("x",-@opts.height/2)
      .attr("y", @opts.width / 2)
      .attr("dy", ".31em")
      .attr("text-anchor", "middle")
      .attr("transform","rotate(-90)translate(0,-#{(@opts.width/2)+30})")
      .text(@opts.y_axis_title)
  
  # Group to hold all the points
  point_group = svg.append("svg:g")
  
  # This is used for highlighting more than one block
  stickySelected = false
  point_group.on('mousedown',(d) -> 
    # d3.selectAll("rect.selected").classed('selected',false).style("fill","grey"); 
    stickySelected = true
    d3.event.preventDefault())
  point_group.on('mouseup',(d) ->  stickySelected = false )
  
  empty = true
  
  distribution_move = (d) ->
    return unless empty == true
    # Get the mouse coordinates relative to the origin of the svg group
    m = d3.svg.mouse(svg.node())    
    # Translate those coordinates into mean and probability
    that.opts.mean = x.invert(m[0])
    that.opts.standard_deviation = inverse_probability_in_mean_bin(y.invert(m[1])/100,that.opts.mean, x_step) 
    drawDistributionLine()
    d3.event.preventDefault();
      
  click_rect.on('click', distribution_move )
    
  # Draws a distribution line
  drawDistributionLine = () ->
    return unless that.opts.mean? && that.opts.standard_deviation?

    # Point to line mapping
    line = d3.svg.line().x((d) -> x(d.x)).y((d) -> y(d.y))
    
    # Calculate the points
    points = x.ticks(100).map( (d) -> {x:d, y: probability_in_bin(d,that.opts.mean,that.opts.standard_deviation,x_step)*100 } )
    
    curve = svg.selectAll('path.distribution')
        .data([points])
    
    curve.enter().append('svg:path')
        .attr('class','distribution')
    
    curve.transition().duration(500).attr('d',line)
    
    curve.on
  
  drawDistributionLine()
  
  values_to_ids = (d) -> d.key
  values_to_frequencies = (d) -> d.values
  iteration_to_id = (d) -> +d.id
  
  # Removes histogram points from the chart
  @clear = () ->    
    point_group.selectAll("g.value").remove()
    empty = true
  
  # Updates the histogram points on the chart
  @update = (data) ->
    empty = false
    
    # Turn the data into buckets    
    buckets = nesting_operator.entries(data)
    
    # Add a group for each bucket
    values = point_group.selectAll("g.value")
      .data(buckets,values_to_ids)
      
    values.enter().append("svg:g")
      .attr("class", "value")
      .attr("transform", (d) -> "translate(#{x(+d.key-(x_step/2))},0)")

    values.exit().remove()
    
    # Add a rectangle for each element in each bucket
    frequencies = values.selectAll("rect")
        .data(values_to_frequencies,iteration_to_id)       
        
    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block block#{d.id}")
        .attr("y", (d,i) -> that.opts.height - ((i+1)*block_height) )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover', (d) -> d3.selectAll(".block#{d.id}").classed("selected",true).style("fill", "yellow") )
        .on('mouseout', (d) -> 
          return if stickySelected == true
          d3.selectAll("rect.selected").classed("selected",false).style("fill", "grey")
        )
        .style("fill", "yellow")
        .transition()
          .duration(1000)
          .style("fill", "grey");
          
    
    frequencies.exit().remove()
  
  this

histogram.defaults =
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
  property: (d) -> d
  bins:     50
  title:    null
  x_axis_suffix: ""
  x_axis_title: null 
  y_axis_suffix: "%"
  y_axis_title: "Probability"

scatterplot = (@opts = {}) ->
  # Set default options
  for own key, value of scatterplot.defaults
    @opts[key] = value unless @opts[key]?
  
  that = this
    
  # Set up scales
  x = d3.scale.linear().domain([@opts.x_min,@opts.x_max]).range([0, @opts.width])
  y = d3.scale.linear().domain([@opts.y_min,@opts.y_max]).range([@opts.height, 0])
    
  tag = d3.select(@opts.tag)

  tag.append("h2").text(@opts.title) if @opts.title?

  # Add a transformation box so we leave space around the edges for axis
  svg = tag.append("svg:svg")
      .attr("width", @opts.width + @opts.padding * 2)
      .attr("height", @opts.height + @opts.padding * 2)
    .append("svg:g")
      .attr("transform", "translate(" + @opts.padding + "," + @opts.padding + ")")
  
  xrule = svg.selectAll("g.x")
      .data(x.ticks(@opts.x_ticks))
    .enter().append("svg:g")
      .attr("class", "x");

  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", @opts.height);

  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", @opts.height + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text( (d) -> x.tickFormat(that.opts.x_ticks)(d)+that.opts.x_axis_suffix );

  if @opts.x_axis_title?    
    svg.append("svg:text")
      .attr("x",@opts.width/2)
      .attr("y", @opts.height + 18)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(@opts.x_axis_title)

  
  yrule = svg.selectAll("g.y")
      .data(y.ticks(@opts.y_ticks))
    .enter().append("svg:g")
      .attr("class", "y");

  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", @opts.width)
      .attr("y1", y)
      .attr("y2", y);

  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text( (d) -> y.tickFormat(that.opts.y_ticks)(d)+that.opts.y_axis_suffix );
  
  if @opts.y_axis_title?
    svg.append("svg:text")
      .attr("x",-@opts.height/2)
      .attr("y", @opts.width / 2)
      .attr("dy", ".31em")
      .attr("text-anchor", "middle")
      .attr("transform","rotate(-90)translate(0,-#{(@opts.width/2)+30})")
      .text(@opts.y_axis_title)

  point_group = svg.append("svg:g")
  stickySelected = false  
  point_group.on('mousedown',(d) -> d3.selectAll("rect.stickySelected").classed('stickySelected',false); stickySelected = true )
  point_group.on('mouseup',(d) -> stickySelected = false )  
  
  iteration_to_id = (d) -> d.id
  block_width = 5
  block_height = 5
  
  @clear = () ->
    point_group.selectAll("rect.block").remove()
  
  @update = (data) ->

    frequencies = point_group.selectAll("rect.block")
        .data(data,iteration_to_id)       

    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block block#{d.id}")
        .attr("x", (d) -> x(that.opts.x_property(d)) )
        .attr("y", (d) -> y(that.opts.y_property(d))-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover', (d) -> 
          d3.selectAll("rect.selected").classed('selected',false)
          if stickySelected == true
            d3.selectAll(".block#{d.id}").classed('stickySelected',true)
          else
            d3.selectAll(".block#{d.id}").classed('selected',true)
        )
        .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))
        .style("fill", "yellow")
        .transition()
          .duration(1000)
          .style("fill", "grey");
        
    frequencies.exit().remove()

  this

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

charts = {}
iterations = []
running = false
worker = null

setup = () ->
    # Create the charts
    charts['capital_cost'] = new histogram(tag:'#capital', x_axis_title:"Capital cost (£/kW)", mean:100 ,standard_deviation:30,property: (d) -> d.capital_cost)
    charts['operating_cost'] = new histogram(tag:"#operating", x_axis_title:"Operating cost (£/MWh)", mean:100, standard_deviation:50, property: (d) -> d.operating_cost)
    charts['fuel_cost'] = new histogram(tag:"#fuel",x_axis_title:"Fuel cost (£/MWh)",mean:100 ,standard_deviation:50, property: (d) -> d.fuel_cost)
    charts['efficiency'] = new histogram(tag:"#efficiency", x_axis_title:"Efficiency", x_axis_suffix: "%", x_max: 100, mean:40, standard_deviation:5, property:(d) -> d.efficiency)
    charts['availability'] = new histogram(tag:"#availability", x_axis_title:"Availability or capacity factor (% of hours operating)", x_axis_suffix:"%", x_max: 100, mean:80, standard_deviation:3 ,property:(d) -> d.availability)
    charts['economic_life'] = new histogram(tag:"#life", x_axis_title:"Economic life (years)", x_max: 50, mean:30, standard_deviation:5, property:(d) -> d.economic_life)
    charts['hurdle_rate'] = new histogram(tag:"#hurdle", x_axis_title:"Investor's hurdle rate (apr)", x_axis_suffix: "%", x_max: 20, mean:10, standard_deviation:3, property:(d) -> d.hurdle_rate)
    charts['capital_available'] = new histogram(tag: "#quantity", x_axis_title:"Investor's capital available £", mean:100, standard_deviation:30, property:(d) -> d.quantity)
    charts['price'] = new histogram(tag: "#price", x_axis_title:"Price of electricity £/MWh", mean:200, standard_deviation:60, property:(d) -> d.price)   
    charts['deployment'] = new histogram(tag: "#deployment", x_axis_title: "Quantity deployed MW", property: (d) -> d.deployment)
    charts['energy_delivered'] = new histogram(tag: "#energyDelivered", x_axis_title: "Energy delivered MWh", property: (d) -> d.energyDelivered)
    charts['public_spend'] = new histogram(tag: "#publicSpend", x_axis_title: "Public expenditure £", x_max: 2000, property: (d) -> d.publicSpend)
    charts['public_spend_against_energy'] = new scatterplot(tag: '#spendEnergyDelivered', x_axis_title: "Public expenditure £", y_axis_title: "Energy delivered MWh", x_max: 2000, y_max: 300, x_property: ((d) -> d.publicSpend), y_property: ((d) -> d.energyDelivered))
    charts['energy_per_public_spend_against_public_spend'] = new scatterplot(tag:'#energyPerPoundAgainstPounds', x_axis_title:"Public expenditure £", y_axis_title:"Energy per pound of public spend MWh/£", x_max:2000, y_max:0.2, x_property:((d) -> d.publicSpend), y_property:((d) -> (d.energyDelivered / d.publicSpend)))
  
    # Set up the controls
    d3.select("#oneRun").on('click',() -> start(1); return false)
    d3.select("#tenRuns").on('click',() -> start(10); return false)
    d3.select("#hundredRuns").on('click',() -> start(100); return false)
    d3.select("#fiveHundredRuns").on('click',() -> start(500); return false)
    d3.select("#stopButton").on('click',() -> stop(); return false)
    d3.select("#clearButton").on('click',() -> clear(); return false)

distributions = () ->
  parameters = {}
  for own name, chart of charts
    if chart.opts.mean? && chart.opts.standard_deviation?
      parameters[name] = { mean: chart.opts.mean, sd: chart.opts.standard_deviation }
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
  console.log distributions()
  worker.postMessage(starting_id: iterations.length, number_of_iterations: number_of_iterations, distributions: distributions());

clear = () ->
  stop()
  iterations = []
  chart.clear() for own name,chart of charts
  d3.select("#message}").text("")
  