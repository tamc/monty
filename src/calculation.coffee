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

# The computation
iteration = (@id,@distributions) ->
  # Expects distribution of the form
  # { 
  #   capital_cost: {mean: 100, sd: 10 },
  #   hurdle_rate: {meain:100, sd: 10}
  # }
  for own key, value of distributions
    @[key] = randomValue(value.mean,value.sd)
  
  @hurdle_rate = @hurdle_rate / 100 # Turn into percentage
  @availability = @availability / 100 
  @efficiency = @efficiency / 100
  
  @annualCapitalCost = @capital_cost * @hurdle_rate * Math.pow(1+@hurdle_rate,@economic_life) / ( Math.pow(1+@hurdle_rate,@loan_period) - 1)
  @annualCost = (@fuel_cost / @efficiency) + @operating_cost + @annualCapitalCost
  @annualIncome = @availability * ( @price + @subsidy )
  @profit = @annualIncome - @annualCost
  if @profit > 0
    @deployment = (@capital_available / @capital_cost)
    @energyDelivered = @deployment *  @availability
    @publicSpend = @energyDelivered * @subsidy
  else
    @profit = 0
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