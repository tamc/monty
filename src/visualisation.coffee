normalZ = (x,mean,standard_deviation) ->
  a = x - mean;
  Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation); 

# Drawing function
histogram = (tag,title,mean,standard_deviation,property) ->
  w = 200
  h = 200
  p = 30
  x = d3.scale.linear().domain([0,300]).range([0, w])
  y = d3.scale.linear().domain([0,20]).range([h, 0])
  x_step = (x.domain()[1] - x.domain()[0])/50
  nesting_operator = d3.nest().key((d) -> Math.round(property(d) / x_step) * x_step )
  block_width = x(x_step)-x(0)
  block_height = (h/(500/20))
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
      .text( (d) -> y.tickFormat(10)(d)+"%" );

  # Add the black box surround
  svg.append("svg:rect")
      .attr("width", w)
      .attr("height", h+1);
  
  # Add a normal distribution line
  points = x.ticks(100).map( (d) ->
    {x:d, y: normalZ(d,mean,standard_deviation)*1000 }
    )
    
  line = d3.svg.line().x((d) -> x(d.x)).y((d) -> y(d.y))
  
  svg.append('svg:path')
      .attr('class','distribution')
      .attr('d',line(points))
  
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
      .attr("transform", (d) -> "translate(#{x(+d.key)},0)")

    values.exit().remove()
    
    # Add a rectangle for each element in each bucket
    frequencies = values.selectAll("rect")
        .data(values_to_frequencies,iteration_to_id)       
    
    frequencies.classed('newblock',false)
      
    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block newblock block#{d.id}")
        # .attr("x", (d,i) -> x(property(d)) )
        .attr("y", (d,i) -> y(i)-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover',(d) -> d3.selectAll(".block#{d.id}").classed('selected',true))
        .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))
    
    frequencies.exit().remove()
  
  @finished = ->
     frequencies = values.selectAll("rect")
          .classed('newblock',false)
  
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
  block_width = 5
  block_height = 5
  
  @update = (data) ->

    frequencies = svg.selectAll("rect.block")
        .data(data,iteration_to_id)       

    frequencies.classed('newblock',false)

    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block newblock block#{d.id}")
        .attr("x", (d) -> x(x_property(d)) )
        .attr("y", (d) -> y(y_property(d))-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
        .on('mouseover',(d) -> d3.selectAll(".block#{d.id}").classed('selected',true))
        .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))

    frequencies.exit().remove()

  this

draw = () ->
  charts = [
    # Inputs
    new histogram("#capital","Capital cost",100,20, (d) -> d.technology.capital_cost ),
    new histogram("#operating","Operating cost",100,60, (d) -> d.technology.operating_cost ),
    new histogram("#fuel","Fuel cost",100,60, (d) -> d.technology.fuel_cost ),
    new histogram("#output","Output",1,0.3, (d) -> d.technology.output ),
    new histogram("#hurdle","Hurdle rate",0.1,0.03, (d) -> d.investors.hurdle_rate ),
    new histogram("#quantity","Investors",100,30, (d) -> d.investors.quantity ),
    new histogram("#price","Price",200,60, (d) -> d.environment.price ),
    # Dependent variables
    new histogram("#deployment","Quantity deployed",100,60, (d) -> d.deployment ),
    new histogram("#energyDelivered","Energy delivered",100,60, (d) -> d.energyDelivered ),
    new histogram("#publicSpend","Public expenditure",100,60, (d) -> d.publicSpend ),
    # Results
    new scatterplot('#spendEnergyDelivered',"Spend against energy delivered",0,3000,0,300,((d) -> d.publicSpend),((d) -> d.energyDelivered))
    new scatterplot('#energyPerPoundAgainstPounds',"Energy per pound of public spend against spend",0,3000,0,0.2,((d) -> d.publicSpend),((d) -> (d.energyDelivered / d.publicSpend)))
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