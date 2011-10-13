numbers = [
  {attr:'target', name: 'Target deployment', value:20, 'unit':'TWh/yr'},
  {attr:'price', name: 'Electricity price', value:71,unit:'£/MWh'}
  {attr:'capital_cost', name: 'Capital cost', value:2211, 'unit':'£/kW'}
  {attr:'operating_cost', name: 'Operating cost', value:132,unit:"£/kW/yr"},
  {attr:'availability', name: 'Average output', value:30,unit:"% of peak output"},
  {attr:'economic_life', name: 'Economic life', value:25,unit:"years"},
  {attr:'hurdle_rate', name: "Investor's hurdle rate", value:13,unit:"%"},
  {attr:'investorCapexRequired', name: 'Required private investment', value:"?",unit:"£bn"},
  {attr:'subsidy', name: 'Subsidy', value:"?", 'unit':'£/MWh'},
  {attr:'publicSpend', name: 'Public spend', value:"?", 'unit':'£bn total'}
]

setup = () ->
  
  d3.select("#calculate").on('click',() -> update_outputs(); return false)

  input_table = d3.selectAll('#table').append('table')

  new_input_rows = input_table.selectAll('tr')
              .data(numbers,(d) -> d.attr )
            .enter().append('tr')
  
  new_input_rows.attr('id',(d) -> d.attr )
  new_input_rows.append('td').text((d) -> d.name)
  new_input_rows.append('td').classed('value',true).text((d) -> d.value)
  new_input_rows.append('td').text((d) -> d.unit) 
  
required_subsidy = (inputs) ->
  for i in inputs
    @[i.attr] = i.value
  
  @fuel_cost = 0
  @efficiency = 100
    
  @annualCapitalCost = @capital_cost * (@hurdle_rate/100) * Math.pow(1+(@hurdle_rate/100), @economic_life) / ( Math.pow( 1+(@hurdle_rate/100),@economic_life) - 1)
  @annualOutput = (1 * 365.25 * 24 / 1000) * (@availability / 100)
  @annualCost = (@annualOutput * @fuel_cost / (@efficiency / 100)) + @operating_cost + @annualCapitalCost
  @annualIncome = @annualOutput * ( @price)
  @subsidy = (@annualCost - @annualIncome)/@annualOutput
  @investorCapexRequired = (@target / @annualOutput) * @capital_cost / 1000
  @publicSpend = @subsidy * @target / 1000
  
  outputs = []
  
  for i in inputs
    i.value = @[i.attr]
  
  inputs

update_outputs = () ->
  new_outputs = required_subsidy(numbers)
  output_values = d3.selectAll('#table tr td.value').data(new_outputs,(d) -> d.attr ).text((d) -> Math.round(d.value,0))  