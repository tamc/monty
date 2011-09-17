# Drawing function
histogram = (tag,title,mean,standard_deviation,property) ->
  w = 250
  h = 250
  p = 20
  x = d3.scale.linear().domain([mean - 3*standard_deviation,mean + 3*standard_deviation]).range([0, w])
  y = d3.scale.linear().domain([0,0.2*200]).range([h, 0])
  
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

  # Add the black box surround
  svg.append("svg:rect")
      .attr("width", w)
      .attr("height", h+1);
  
  iteration_to_id = (d) -> d.id
  block_width = x(1)-x(0)
  block_height = y(0)-y(1)
  
  @update = (data) ->

    frequencies = svg.selectAll("rect.block")
        .data(data,iteration_to_id)       

    frequencies.classed('newblock',false)

    frequencies.enter().append("svg:rect")
        .classed("block",true)
        .classed('newblock',true)
        .attr("x", (d) -> x(x_property(d)) )
        .attr("y", (d) -> y(y_property(d))-block_height )
        .attr("width",block_width)
        .attr("height",block_height)

    frequencies.exit().remove()

  this

draw = () ->
  charts = [
    # Inputs
    new histogram("#capital","Capital cost",100,20, (d) -> d.technology.capital_cost ),
    new histogram("#operating","Operating cost",100,60, (d) -> d.technology.operating_cost ),
    new histogram("#fuel","Fuel cost",100,60, (d) -> d.technology.fuel_cost ),
    new histogram("#output","Output",100,60, (d) -> d.technology.output ),
    new histogram("#hurdle","Hurdle rate",0.1,0.03, (d) -> d.investors.hurdle_rate ),
    new histogram("#quantity","Investors",100,60, (d) -> d.investors.quantity ),
    new histogram("#price","Price",100,60, (d) -> d.environment.price ),
    # Dependent variables
    new histogram("#deployment","Quantity deployed",100,60, (d) -> d.deployment ),
    new histogram("#energyDelivered","Energy delivered",100,60, (d) -> d.energyDelivered ),
    new histogram("#publicSpend","Public expenditure",100,60, (d) -> d.publicSpend ),
    # Results
    new scatterplot('#spendEnergyDelivered',"Spend against energy delivered",0,3000,0,300,((d) -> d.publicSpend),((d) -> d.energyDelivered))
    new scatterplot('#energyPerPoundAgainstPounds',"Energy per pound of public spend against spend",0,3000,0,10,((d) -> d.publicSpend),((d) -> (d.energyDelivered / d.publicSpend)))
  ]

  iterations = []
  worker = new Worker('../js/calculation.js')
  worker.onmessage = (event) ->
    iterations.push(event.data)
    chart.update(iterations) for chart in charts
  worker.onerror = (error) ->  
    console.log("Calculation error: " + error.message + "\n")
    throw error
  worker.postMessage();