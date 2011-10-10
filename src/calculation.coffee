# Utility functions for different distributions

fixedValue = (value) ->
  value.value

randomNormalValueMean0Sd1 = () ->
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
  
randomNormalValue = (value) ->
  (randomNormalValueMean0Sd1() * value.sd) + value.mean


distributionFunctions = {
  'fixed'  : fixedValue
  'normal' : randomNormalValue
}

# The computation
iteration = (@id,@distributions) ->
  # Expects distribution of the form
  # { 
  #   capital_cost: {mean: 100, sd: 10 },
  #   hurdle_rate: {meain:100, sd: 10}
  # }
  for own key, value of distributions
    @[key] = distributionFunctions[value.distribution](value)
  
  # Can't allow anything less than zero
  for own key, value of this
    @[key] = 0 if value < 0
    
  # Can't allow efficiency or availability greater than a hundred percent
  @efficiency = 100 if @efficiency > 100
  @availability = 100 if @availability > 100
    
  @annualCapitalCost = @capital_cost * (@hurdle_rate/100) * Math.pow(1+(@hurdle_rate/100),@economic_life) / ( Math.pow(1+(@hurdle_rate/100),@economic_life) - 1)
  @annualOutput = (1 * 365.25 * 24 / 1000) * (@availability / 100) # Converts kW to MWh
  @annualCost = (@annualOutput * @fuel_cost / (@efficiency / 100)) + @operating_cost + @annualCapitalCost
  @cost_per_MWh = @annualCost / @annualOutput
  @annualIncome = @annualOutput * ( @price + @subsidy )
  @profit = @annualIncome - @annualCost
  if @profit > 0
    @deployment = (@capital_available * 1e9 / @capital_cost) / 1000 # Deployment in MW
    @energyDelivered = @deployment * @annualOutput / 1000 # Energy delivered in TWh
    @publicSpend = @energyDelivered * @subsidy / 1000
  else
    @deployment = 0
    @energyDelivered = 0
    @publicSpend = 0
    
  return this

@onmessage = (event) ->
  starting_id = event.data.starting_id
  distributions = event.data.distributions
  for i in [1..event.data.number_of_iterations]
    @postMessage(new iteration(i+starting_id,distributions))
    false
  @close