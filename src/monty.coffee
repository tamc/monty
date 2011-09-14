# Utility functions
randomNormalValue = () ->
  # A poor man's approximation!
  (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
  
randomValue = (mean,standard_deviation,precision = 1) ->
  Math.round(((randomNormalValue() * standard_deviation) + mean)/precision) * precision 

# The variables
technology = () ->
  @capital_cost   = randomValue(100,20)
  @operating_cost = randomValue(100,60)
  @fuel_cost      = randomValue(100,60)
  @output         = randomValue(1,0.3)

investors = () ->
  @hurdle_rate    = randomValue(0.1,0.03,0.01)
  @loan_period    = 10
  @quantity       = randomValue(100,30)

environment = () ->
  @subsidy        = 10
  @price          = randomValue(200,60)

# The computation
iteration = (@technology,@investors,@environment) ->
  @isTechnologyBuilt = () ->
    @annualIncome() > @annualCost()
  
  @annualIncome = () ->
    @technology.output * ( @environment.price + @environment.subsidy )
  
  @annualCost = () ->
    @technology.fuel_cost + @technology.operating_cost + @annualCapitalCost()
    
  @annualCapitalCost = () ->
    @technology.capital_cost * @investors.hurdle_rate * Math.pow(1+@investors.hurdle_rate,@investors.loan_period) / ( Math.pow(1+@investors.hurdle_rate,@investors.loan_period) - 1)

  @deployment = @isTechnologyBuilt() * @investors.quantity
  @publicSpend = @deployment * @environment.subsidy
  @energyDelivered = @deployment * @technology.output
  
    
  return this

# Drawing function
histogram = (tag,data) ->
  w = 450
  h = 450
  p = 20
  x = d3.scale.linear().domain([0,200]).range([0, w])
  y = d3.scale.linear().domain([0,200]).range([h, 0])
  
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

  svg.append("svg:rect")
      .attr("width", w)
      .attr("height", h);
  
  # Turn the data into buckets
  buckets = d3.nest()
    .key((d) -> 
      d.technology.capital_cost)
    .entries(data)
      
  # Add a group for each bucket
  values = svg.selectAll("g.values")
      .data(buckets)
    .enter().append("svg:g")
      .attr("class", "value")
  
  block_width = x(1)-x(0)
  block_height = y(0)-y(1)
  
  frequencies = values.selectAll("rect")
    .data((d) -> d.values)
    .enter().append("svg:rect")
      .attr("class","block")
      .attr("x", (d,i) -> x(d.technology.capital_cost) )
      .attr("y", (d,i) -> y(i)-block_height )
      .attr("width",block_width)
      .attr("height",block_height)
  
      
draw = () ->
  iterations = (new iteration(new technology, new investors, new environment) for i in [1..1000])
  new histogram("#histogram",iterations)