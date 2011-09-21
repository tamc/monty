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

# Drawing a histogram
histogram = (opts = {}) ->
  # Set default options
  for own key, value of histogram.defaults
    opts[key] = value unless opts[key]?
  
  # Set up scales
  x = d3.scale.linear().domain([opts.x_min,opts.x_max]).range([0, opts.width])
  y = d3.scale.linear().domain([opts.y_min,opts.y_max]).range([opts.height, 0])
  
  # Set up bucket size and corresponding block dimenions
  x_step = (x.domain()[1] - x.domain()[0])/opts.bins
  nesting_operator = d3.nest().key((d) -> Math.round(opts.property(d) / x_step) * x_step )
  block_width = x(x_step) - x(0)
  block_height = opts.height / ((opts.y_max / 100)*500)
  
  # Start the drawing by setting up the surround
  tag = d3.select(opts.tag)
  tag.append("h2").text(opts.title)
  
  # Add a transformation box so we leave space around the edges for axis
  svg = tag.append("svg:svg")
      .attr("width", opts.width + opts.padding * 2)
      .attr("height", opts.height + opts.padding * 2)
    .append("svg:g")
      .attr("transform", "translate(" + opts.padding + "," + opts.padding + ")")
  
  xrule = svg.selectAll("g.x")
      .data(x.ticks(opts.x_ticks))
    .enter().append("svg:g")
      .attr("class", "x");

  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", opts.height);

  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", opts.height + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(x.tickFormat(opts.x_ticks));
  
  yrule = svg.selectAll("g.y")
      .data(y.ticks(opts.y_ticks))
    .enter().append("svg:g")
      .attr("class", "y");

  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", opts.width)
      .attr("y1", y)
      .attr("y2", y);

  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text( (d) -> y.tickFormat(opts.x_ticks)(d)+"%" );
  
  point_group = svg.append("svg:g")
  
  if opts.mean? && opts.standard_deviation?
    # Add a normal distribution line
    points = x.ticks(100).map( (d) ->
      {x:d, y: probability_in_bin(d,opts.mean,opts.standard_deviation,x_step)*100 }
      )
    
    line = d3.svg.line().x((d) -> x(d.x)).y((d) -> y(d.y))
  
    svg.append('svg:path')
        .attr('class','distribution')
        .attr('d',line(points))
  
  values_to_ids = (d) -> d.key
  values_to_frequencies = (d) -> d.values
  iteration_to_id = (d) -> +d.id
  
  @clear = () ->
    point_group.selectAll("g.value").remove()
  
  @update = (data) ->
        
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
        .attr("class",(d) -> "block selected block#{d.id}")
        # .attr("x", (d,i) -> x(property(d)) )
        .attr("y", (d,i) -> opts.height - ((i+1)*block_height) )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover',(d) -> d3.selectAll("rect.selected").classed('selected',false); ; d3.selectAll(".block#{d.id}").classed('selected',true))
        .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))
    
    frequencies.exit().remove()
  
  this

histogram.defaults =
  tag:      "body"
  width:    250
  height:   250
  padding:  30
  x_min:    0
  x_max:    300
  y_min:    0
  y_max:    10
  x_ticks:  10
  y_ticks:  10
  property: (d) -> d
  bins:     50
  title:    "Histogram"

scatterplot = (tag,title,x_low,x_high,y_low,y_high,x_property,y_property) ->
  w = 250
  h = 250
  p = 20
  x = d3.scale.linear().domain([x_low,x_high]).range([0, w])
  y = d3.scale.linear().domain([y_low,y_high]).range([h, 0])

  tag = d3.select(tag)

  tag.append("h2").text(title)

  svg = tag.append("svg:svg")
      .attr("width", w + p * 2)
      .attr("height", h + p * 2)
    .append("svg:g")
      .attr("transform", "translate(" + p + "," + p + ")")

  xrule = svg.selectAll("g.x")
      .data(x.ticks(10))
    .enter().append("svg:g")
      .attr("class", "x");

  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", h);

  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", h + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(x.tickFormat(10));

  yrule = svg.selectAll("g.y")
      .data(y.ticks(10))
    .enter().append("svg:g")
      .attr("class", "y");

  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", w)
      .attr("y1", y)
      .attr("y2", y);

  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text(y.tickFormat(10));
  
  point_group = svg.append("svg:g")
  
  iteration_to_id = (d) -> d.id
  block_width = 5
  block_height = 5
  
  @clear = () ->
    point_group.selectAll("rect.block").remove()
  
  @update = (data) ->

    frequencies = point_group.selectAll("rect.block")
        .data(data,iteration_to_id)       

    frequencies.classed('newblock',false)

    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block selected block#{d.id}")
        .attr("x", (d) -> x(x_property(d)) )
        .attr("y", (d) -> y(y_property(d))-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover',(d) -> d3.selectAll("rect.selected").classed('selected',false); d3.selectAll(".block#{d.id}").classed('selected',true))
        .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))

    frequencies.exit().remove()

  this

charts = []
iterations = []
running = false
worker = null

setup = () ->
    # Inputs
    charts.push(new histogram(tag: '#capital'   ,title:"Capital cost"   ,mean:100 ,standard_deviation:30  ,property: (d) -> d.technology.capital_cost))
    charts.push(new histogram(tag: "#capital"   ,title:"Capital cost"   ,mean:100 ,standard_deviation:20  ,property: (d) -> d.technology.capital_cost ))
    charts.push(new histogram(tag: "#operating" ,title:"Operating cost" ,mean:100 ,standard_deviation:50  ,property: (d) -> d.technology.operating_cost ))
    charts.push(new histogram(tag: "#fuel"      ,title:"Fuel cost"      ,mean:100 ,standard_deviation:50  ,property: (d) -> d.technology.fuel_cost ))
    charts.push(new histogram(tag: "#output"    ,title:"Output"         ,mean:1   ,standard_deviation:0.3 ,property: ((d) -> d.technology.output), x_max: 2  ))
    charts.push(new histogram(tag: "#hurdle"    ,title:"Hurdle rate"    ,mean:10 ,standard_deviation:3,property: ((d) -> d.investors.hurdle_rate * 100), x_max: 20 ))
    charts.push(new histogram(tag: "#quantity"  ,title:"Investors"      ,mean:100 ,standard_deviation:30  ,property: (d) -> d.investors.quantity ))
    charts.push(new histogram(tag: "#price"     ,title:"Price"          ,mean:200 ,standard_deviation:60  ,property: (d) -> d.environment.price ))

    charts.push(new histogram(tag: "#deployment"      ,title: "Quantity deployed"   ,property: (d) -> d.deployment ))
    charts.push(new histogram(tag: "#energyDelivered" ,title: "Energy delivered"    ,property: (d) -> d.energyDelivered ))
    charts.push(new histogram(tag: "#publicSpend"     ,title: "Public expenditure"  , x_max: 2000, property: (d) -> d.publicSpend ))

    charts.push(new scatterplot('#spendEnergyDelivered',"Spend against energy delivered",0,2000,0,300,((d) -> d.publicSpend),((d) -> d.energyDelivered)))
    charts.push(new scatterplot('#energyPerPoundAgainstPounds',"Energy per pound of public spend against spend",0,2000,0,0.2,((d) -> d.publicSpend),((d) -> (d.energyDelivered / d.publicSpend))))
    
    d3.select("#oneRun").on('click',() -> start(1); return false)
    d3.select("#tenRuns").on('click',() -> start(10); return false)
    d3.select("#hundredRuns").on('click',() -> start(100); return false)
    d3.select("#fiveHundredRuns").on('click',() -> start(500); return false)
    d3.select("#stopButton").on('click',() -> stop(); return false)
    d3.select("#clearButton").on('click',() -> clear(); return false)

stop = () ->
  return unless running == true
  running = false
  worker.terminate()

start = (number_of_iterations = 500) ->  
  d3.selectAll("rect.selected").classed('selected',false)
  worker = new Worker('../js/calculation.js')
  running = true
  worker.onmessage = (event) ->
    iterations.push(event.data)
    chart.update(iterations) for chart in charts
  worker.onerror = (error) ->  
    console.log("Calculation error: " + error.message + "\n")
    throw error
  worker.postMessage(starting_id: iterations.length, number_of_iterations: number_of_iterations);

clear = () ->
  stop()
  iterations = []
  chart.clear() for chart in charts