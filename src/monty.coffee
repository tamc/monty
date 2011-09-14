randomNormalValue = () ->
  # A poor man's approximation!
  (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
  
randomValue = (mean,standard_deviation) ->
  (randomNormalValue() * standard_deviation) + mean

technology = () ->
  @capital_cost   = randomValue(100,60)
  @operating_cost = randomValue(100,60)
  @fuel_cost      = randomValue(100,60)
  @output         = randomValue(1,0.3)

investors = () ->
  @hurdle_rate    = randomValue(0.1,0.01)
  @loan_period    = 10
  @quantity       = randomValue(100,30)

environment = () ->
  @subsidy        = 10
  @price          = randomValue(200,60)

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

  