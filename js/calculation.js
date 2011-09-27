var iteration, randomNormalValue, randomValue;
var __hasProp = Object.prototype.hasOwnProperty;
randomNormalValue = function() {
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
randomValue = function(mean, standard_deviation) {
  return (randomNormalValue() * standard_deviation) + mean;
};
iteration = function(id, distributions) {
  var key, value;
  this.id = id;
  this.distributions = distributions;
  for (key in distributions) {
    if (!__hasProp.call(distributions, key)) continue;
    value = distributions[key];
    this[key] = randomValue(value.mean, value.sd);
  }
  this.hurdle_rate = this.hurdle_rate / 100;
  this.availability = this.availability / 100;
  this.efficiency = this.efficiency / 100;
  this.annualCapitalCost = this.capital_cost * this.hurdle_rate * Math.pow(1 + this.hurdle_rate, this.economic_life) / (Math.pow(1 + this.hurdle_rate, this.loan_period) - 1);
  this.annualCost = (this.fuel_cost / this.efficiency) + this.operating_cost + this.annualCapitalCost;
  this.annualIncome = this.availability * (this.price + this.subsidy);
  this.profit = this.annualIncome - this.annualCost;
  if (this.profit > 0) {
    this.deployment = this.capital_available / this.capital_cost;
    this.energyDelivered = this.deployment * this.availability;
    this.publicSpend = this.energyDelivered * this.subsidy;
  } else {
    this.profit = 0;
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