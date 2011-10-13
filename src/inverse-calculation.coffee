# Utility functions for different distributions

fixedValue = (value) ->
  value.value

meanFromNormal = (value) ->
  value.mean

distributionFunctions = {
  'fixed'  : fixedValue
  'normal' : meanFromNormal
}

# The computation
deployment = (@id,@distributions) ->
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
    
  @annualCapitalCost = @capital_cost * (@hurdle_rate/100) * Math.pow(1+(@hurdle_rate/100), @economic_life) / ( Math.pow( 1+(@hurdle_rate/100),@economic_life) - 1)
  @annualOutput = (1 * 365.25 * 24 / 1000) * (@availability / 100)
  @annualCost = (@annualOutput * @fuel_cost / (@efficiency / 100)) + @operating_cost + @annualCapitalCost
  @annualIncome = @annualOutput * ( @price)
  @subsidy = (@annualCost - @annualIncome)/@annualOutput
  @capital_available = (@energy_delivered / @annualOutput) * @capital_cost / 1000
  @public_spend = @subsidy * @energy_delivered / 1000
    
  return this

@onmessage = (event) ->
  starting_id = event.data.starting_id
  distributions = event.data.distributions
  for i in [1..event.data.number_of_iterations]
    @postMessage(new deployment(i+starting_id,distributions))
    false
  @close