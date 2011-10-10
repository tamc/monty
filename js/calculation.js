var distributionFunctions, fixedValue, iteration, randomNormalValue, randomNormalValueMean0Sd1;
var __hasProp = Object.prototype.hasOwnProperty;
fixedValue = function(value) {
  return value.value;
};
randomNormalValueMean0Sd1 = function() {
  var r, s, x1, x2, y1, y2;
  while (r >= 1.0 || r === void 0) {
    x1 = 2.0 * Math.random() - 1.0;
    x2 = 2.0 * Math.random() - 1.0;
    r = x1 * x1 + x2 * x2;
  }
  s = Math.sqrt((-2.0 * Math.log(r)) / r);
  y1 = x1 * s;
  y2 = x2 * s;
  return y1;
};
randomNormalValue = function(value) {
  return (randomNormalValueMean0Sd1() * value.sd) + value.mean;
};
distributionFunctions = {
  'fixed': fixedValue,
  'normal': randomNormalValue
};
iteration = function(id, distributions) {
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
  this.cost_per_MWh = this.annualCost / this.annualOutput;
  this.annualIncome = this.annualOutput * (this.price + this.subsidy);
  this.profit = this.annualIncome - this.annualCost;
  if (this.profit > 0) {
    this.deployment = (this.capital_available * 1e9 / this.capital_cost) / 1000;
    this.energyDelivered = this.deployment * this.annualOutput / 1000;
    this.publicSpend = this.energyDelivered * this.subsidy / 1000;
  } else {
    this.deployment = 0;
    this.energyDelivered = 0;
    this.publicSpend = 0;
  }
  return this;
};
this.onmessage = function(event) {
  var distributions, i, starting_id, _ref;
  starting_id = event.data.starting_id;
  distributions = event.data.distributions;
  for (i = 1, _ref = event.data.number_of_iterations; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
    this.postMessage(new iteration(i + starting_id, distributions));
    false;
  }
  return this.close;
};