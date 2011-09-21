# Utility functions
randomNormalValue = () ->
  # A poor man's approximation!
  # (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
  # Polar Box-Muller
  while r >= 1.0 || r == undefined
    x1 = 2.0 * Math.random() - 1.0;
    x2 = 2.0 * Math.random() - 1.0;
    r = x1 * x1 + x2 * x2;
  
   s = Math.sqrt( (-2.0 * Math.log( r ) ) / r );
   y1 = x1 * s
   y2 = x2 * s
   y1
  
randomValue = (mean,standard_deviation) ->
  (randomNormalValue() * standard_deviation) + mean

# The variables
technology = () ->
  @capital_cost   = randomValue(100,30)
  @operating_cost = randomValue(100,50)
  @fuel_cost      = randomValue(100,50)
  @output         = randomValue(1,0.3)

investors = () ->
  @hurdle_rate    = randomValue(0.1,0.03)
  @loan_period    = 10
  @quantity       = randomValue(100,30)

environment = () ->
  @subsidy        = 10
  @price          = randomValue(200,60)

# The computation
iteration = (@id,@technology,@investors,@environment) ->
  @isTechnologyBuilt = () ->
    @annualIncome() > @annualCost()
  
  @annualIncome = () ->
    @technology.output * ( @environment.price + @environment.subsidy )
  
  @annualCost = () ->
    @technology.fuel_cost + @technology.operating_cost + @annualCapitalCost()
    
  @annualCapitalCost = () ->
    @technology.capital_cost * @investors.hurdle_rate * Math.pow(1+@investors.hurdle_rate,@investors.loan_period) / ( Math.pow(1+@investors.hurdle_rate,@investors.loan_period) - 1)

  @deployment = @isTechnologyBuilt() * @investors.quantity
  @energyDelivered = @deployment * @technology.output
  @publicSpend = @deployment * @environment.subsidy
  
    
  return this

@onmessage = (event) ->
  starting_id = event.data.starting_id
  for i in [1..event.data.number_of_iterations]
    @postMessage(new iteration(i+starting_id,new technology, new investors, new environment))
    false
  @close