# Utility functions
randomNormalValue = () ->
  # A poor man's approximation!
  (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
  
randomValue = (mean,standard_deviation,precision = 1) ->
  Math.round(((randomNormalValue() * standard_deviation) + mean)/precision) * precision

normalZ = (x,mean,standard_deviation) ->
  a = x - Mean;
  Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation); 

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
  @publicSpend = @deployment * @environment.subsidy
  @energyDelivered = @deployment * @technology.output
  
    
  return this

@onmessage = (data) ->
  for i in [1..500]
    @postMessage(new iteration(i,new technology, new investors, new environment))
    false
  @close