# Drawing function
histogram = (tag,mean,standard_deviation,data) ->
  w = 450
  h = 450
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
      .attr("height", h);
  
  # Add a normal distribution line
  # svg.selectAll('path.normal')
  #     .data(x.ticks(10))
  #   .enter().append('svg:path')
  #     .attr('d'
  #       d3.svg.line()
  #         .x((d) -> console.log(d); x(d))
  #         .y((d) -> y(normalZ(d,mean,standard_deviation))))
  
  nesting_operator = d3.nest().key((d) -> d.technology.capital_cost)
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
      .attr("x", (d) -> console.log("Adding group #{d.key}"); 1 )
      .attr("class", "value")

    values.exit().remove()
    
#     Add a rectangle for each element in each bucket
    frequencies = values.selectAll("rect")
        .data(values_to_frequencies,iteration_to_id)       
    
#    frequencies.classed('block',false)
      
    frequencies.enter().append("svg:rect")
        .classed("block",true)
        .attr("x", (d,i) -> console.log("Adding #{d.id}"); x(d.technology.capital_cost) )
        .attr("y", (d,i) -> y(i)-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
  
  this
      
draw = () ->
  hist = new histogram("#histogram",100,20)
  iterations = []
  worker = new Worker('../js/calculation.js')
  worker.onmessage = (event) ->
    iterations.push(event.data)
    hist.update(iterations)
  worker.onerror = (error) ->  
    console.log("Calculation error: " + error.message + "\n")
    throw error
  worker.postMessage();