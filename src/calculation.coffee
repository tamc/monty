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

irr = (initial_outlay,annual_profit,years) ->
  r = 0.1
  r_last = -0.1
  npv_last = npv(initial_outlay,annual_profit,years,r_last)
  attempts = 0
  while Math.abs(r-r_last) > 0.00001
    break if attempts > 10
    attempts++
    npv_this = npv(initial_outlay,annual_profit,years,r)
    next_r = r - npv_this * ((r - r_last) / (npv_this - npv_last))
    r_last = r
    npv_last = npv_this
    r = next_r
  r
    
npv = (initial_outlay,annual_profit,years,discount_rate) ->
  profit = -initial_outlay
  for year in [1..years]
    discounted_annual_profit = (annual_profit/Math.pow(1+discount_rate,year))
    profit = profit + discounted_annual_profit
  profit
  

# The computation
deployment = (@id,@distributions) ->
  # Expects distribution of the form
  # { 
  #   capital_cost: {mean: 100, sd: 10 },
  #   hurdle_rate: {mean:100, sd: 10}
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
  @internal_rate_of_return = irr(@capital_cost,@profit + @annualCapitalCost,@economic_life) * 100
  if (@internal_rate_of_return - @hurdle_rate) < 0
    # Investment falls rapidly to zero
    @actual_capital_available = @capital_available *  ((@internal_rate_of_return - @hurdle_rate)/4)
    @actual_capital_available = 0 if @actual_capital_available < 0
  else
    # Investment increases gently
    @capital_scale_factor = ((@internal_rate_of_return - @hurdle_rate)/30.0)
    @capital_scale_factor = 1 if @capital_scale_factor > 1
    @actual_capital_available = @capital_available + (3 * @capital_scale_factor) 
  if @actual_capital_available > 0
    @deployment = (@actual_capital_available * 1e9 / @capital_cost) / 1000 # Deployment in MW
    @energy_delivered = @deployment * @annualOutput / 1000 # Energy delivered in TWh
    @public_spend = @energy_delivered * @subsidy / 1000
    @total_profit = @profit * @deployment / 1000000
  else
    @deployment = 0
    @energy_delivered = 0
    @public_spend = 0
    @total_profit = 0
    
  return this

@onmessage = (event) ->
  starting_id = event.data.starting_id
  distributions = event.data.distributions
  for i in [1..event.data.number_of_iterations]
    @postMessage(new deployment(i+starting_id,distributions))
    false
  @close