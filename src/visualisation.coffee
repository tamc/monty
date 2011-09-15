# Drawing function
histogram = (tag,mean,standard_deviation,property) ->
  w = 250
  h = 250
  p = 20
  x = d3.scale.linear().domain([mean - 3*standard_deviation,mean + 3*standard_deviation]).range([0, w])
  y = d3.scale.linear().domain([0,0.2*200]).range([h, 0])
  
  svg = d3.select(tag)
    .append("svg:svg")
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

  # Add the black box surround
  svg.append("svg:rect")
      .attr("width", w)
      .attr("height", h+1);
  
  # Add a normal distribution line
  # svg.selectAll('path.normal')
  #     .data(x.ticks(10))
  #   .enter().append('svg:path')
  #     .attr('d'
  #       d3.svg.line()
  #         .x((d) -> console.log(d); x(d))
  #         .y((d) -> y(normalZ(d,mean,standard_deviation))))
  
  nesting_operator = d3.nest().key(property)
  block_width = x(1)-x(0)
  block_height = y(0)-y(1)
  values_to_ids = (d) -> d.key
  values_to_frequencies = (d) -> d.values
  iteration_to_id = (d) -> +d.id
  
  @update = (data) ->
        
    # Turn the data into buckets    
    buckets = nesting_operator.entries(data)
    
    # Add a group for each bucket
    values = svg.selectAll("g.value")
      .data(buckets,values_to_ids)
      
    values.enter().append("svg:g")
      .attr("class", "value")

    values.exit().remove()
    
    # Add a rectangle for each element in each bucket
    frequencies = values.selectAll("rect")
        .data(values_to_frequencies,iteration_to_id)       
    
    frequencies.classed('newblock',false)
      
    frequencies.enter().append("svg:rect")
        .classed("block",true)
        .classed('newblock',true)
        .attr("x", (d,i) -> x(property(d)) )
        .attr("y", (d,i) -> y(i)-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
    
    frequencies.exit().remove()
  
  this
      
draw = () ->
  histograms = [
    new histogram("#capital",100,20, (d) -> d.technology.capital_cost ),
    new histogram("#operating",100,60, (d) -> d.technology.operating_cost )
    new histogram("#fuel",100,60, (d) -> d.technology.fuel_cost )
    new histogram("#output",100,60, (d) -> d.technology.output )

  ]

  iterations = []
  worker = new Worker('../js/calculation.js')
  worker.onmessage = (event) ->
    iterations.push(event.data)
    histogram.update(iterations) for histogram in histograms
  worker.onerror = (error) ->  
    console.log("Calculation error: " + error.message + "\n")
    throw error
  worker.postMessage();