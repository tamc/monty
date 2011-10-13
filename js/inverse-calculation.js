var deployment, distributionFunctions, fixedValue, meanFromNormal;
var __hasProp = Object.prototype.hasOwnProperty;
fixedValue = function(value) {
  return value.value;
};
meanFromNormal = function(value) {
  return value.mean;
};
distributionFunctions = {
  'fixed': fixedValue,
  'normal': meanFromNormal
};
deployment = function(id, distributions) {
  var key, value;
  this.id = id;
  this.distributions = distributions;
  for (key in distributions) {
    if (!__hasProp.call(distributions, key)) continue;
    value = distributions[key];
    this[key] = distributionFunctions[value.distribution](value);
  }
  for (key in this) {
    if (!__hasProp.call(this, key)) continue;
    value = this[key];
    if (value < 0) {
      this[key] = 0;
    }
  }
  if (this.efficiency > 100) {
    this.efficiency = 100;
  }
  if (this.availability > 100) {
    this.availability = 100;
  }
  this.annualCapitalCost = this.capital_cost * (this.hurdle_rate / 100) * Math.pow(1 + (this.hurdle_rate / 100), this.economic_life) / (Math.pow(1 + (this.hurdle_rate / 100), this.economic_life) - 1);
  this.annualOutput = (1 * 365.25 * 24 / 1000) * (this.availability / 100);
  this.annualCost = (this.annualOutput * this.fuel_cost / (this.efficiency / 100)) + this.operating_cost + this.annualCapitalCost;
  this.annualIncome = this.annualOutput * this.price;
  this.subsidy = (this.annualCost - this.annualIncome) / this.annualOutput;
  this.capital_available = (this.energy_delivered / this.annualOutput) * this.capital_cost / 1000;
  this.public_spend = this.subsidy * this.energy_delivered / 1000;
  return this;
};
this.onmessage = function(event) {
  var distributions, i, starting_id, _ref;
  starting_id = event.data.starting_id;
  distributions = event.data.distributions;
  for (i = 1, _ref = event.data.number_of_iterations; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
    this.postMessage(new deployment(i + starting_id, distributions));
    false;
  }
  return this.close;
};