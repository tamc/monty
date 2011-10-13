var numbers, required_subsidy, setup, update_outputs;
numbers = [
  {
    attr: 'target',
    name: 'Target deployment',
    value: 20,
    'unit': 'TWh/yr'
  }, {
    attr: 'price',
    name: 'Electricity price',
    value: 71,
    unit: '£/MWh'
  }, {
    attr: 'capital_cost',
    name: 'Capital cost',
    value: 2211,
    'unit': '£/kW'
  }, {
    attr: 'operating_cost',
    name: 'Operating cost',
    value: 132,
    unit: "£/kW/yr"
  }, {
    attr: 'availability',
    name: 'Average output',
    value: 30,
    unit: "% of peak output"
  }, {
    attr: 'economic_life',
    name: 'Economic life',
    value: 25,
    unit: "years"
  }, {
    attr: 'hurdle_rate',
    name: "Investor's hurdle rate",
    value: 13,
    unit: "%"
  }, {
    attr: 'investorCapexRequired',
    name: 'Required private investment',
    value: "?",
    unit: "£bn"
  }, {
    attr: 'subsidy',
    name: 'Subsidy',
    value: "?",
    'unit': '£/MWh'
  }, {
    attr: 'publicSpend',
    name: 'Public spend',
    value: "?",
    'unit': '£bn total'
  }
];
setup = function() {
  var input_table, new_input_rows;
  d3.select("#calculate").on('click', function() {
    update_outputs();
    return false;
  });
  input_table = d3.selectAll('#table').append('table');
  new_input_rows = input_table.selectAll('tr').data(numbers, function(d) {
    return d.attr;
  }).enter().append('tr');
  new_input_rows.attr('id', function(d) {
    return d.attr;
  });
  new_input_rows.append('td').text(function(d) {
    return d.name;
  });
  new_input_rows.append('td').classed('value', true).text(function(d) {
    return d.value;
  });
  return new_input_rows.append('td').text(function(d) {
    return d.unit;
  });
};
required_subsidy = function(inputs) {
  var i, outputs, _i, _j, _len, _len2;
  for (_i = 0, _len = inputs.length; _i < _len; _i++) {
    i = inputs[_i];
    this[i.attr] = i.value;
  }
  this.fuel_cost = 0;
  this.efficiency = 100;
  this.annualCapitalCost = this.capital_cost * (this.hurdle_rate / 100) * Math.pow(1 + (this.hurdle_rate / 100), this.economic_life) / (Math.pow(1 + (this.hurdle_rate / 100), this.economic_life) - 1);
  this.annualOutput = (1 * 365.25 * 24 / 1000) * (this.availability / 100);
  this.annualCost = (this.annualOutput * this.fuel_cost / (this.efficiency / 100)) + this.operating_cost + this.annualCapitalCost;
  this.annualIncome = this.annualOutput * this.price;
  this.subsidy = (this.annualCost - this.annualIncome) / this.annualOutput;
  this.investorCapexRequired = (this.target / this.annualOutput) * this.capital_cost / 1000;
  this.publicSpend = this.subsidy * this.target / 1000;
  outputs = [];
  for (_j = 0, _len2 = inputs.length; _j < _len2; _j++) {
    i = inputs[_j];
    i.value = this[i.attr];
  }
  return inputs;
};
update_outputs = function() {
  var new_outputs, output_values;
  new_outputs = required_subsidy(numbers);
  return output_values = d3.selectAll('#table tr td.value').data(new_outputs, function(d) {
    return d.attr;
  }).text(function(d) {
    return Math.round(d.value, 0);
  });
};