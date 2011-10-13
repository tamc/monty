var deployment, distributionFunctions, fixedValue, irr, npv, randomNormalValue, randomNormalValueMean0Sd1;
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
irr = function(initial_outlay, annual_profit, years) {
  var attempts, next_r, npv_last, npv_this, r, r_last;
  r = 0.1;
  r_last = -0.1;
  npv_last = npv(initial_outlay, annual_profit, years, r_last);
  attempts = 0;
  while (Math.abs(r - r_last) > 0.00001) {
    if (attempts > 10) {
      break;
    }
    attempts++;
    npv_this = npv(initial_outlay, annual_profit, years, r);
    next_r = r - npv_this * ((r - r_last) / (npv_this - npv_last));
    r_last = r;
    npv_last = npv_this;
    r = next_r;
  }
  return r;
};
npv = function(initial_outlay, annual_profit, years, discount_rate) {
  var discounted_annual_profit, profit, year;
  profit = -initial_outlay;
  for (year = 1; 1 <= years ? year <= years : year >= years; 1 <= years ? year++ : year--) {
    discounted_annual_profit = annual_profit / Math.pow(1 + discount_rate, year);
    profit = profit + discounted_annual_profit;
  }
  return profit;
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
  this.cost_per_MWh = this.annualCost / this.annualOutput;
  this.annualIncome = this.annualOutput * (this.price + this.subsidy);
  this.profit = this.annualIncome - this.annualCost;
  this.internal_rate_of_return = irr(this.capital_cost, this.profit + this.annualCapitalCost, this.economic_life) * 100;
  if ((this.internal_rate_of_return - this.hurdle_rate) < 0) {
    this.actual_capital_available = this.capital_available * ((this.internal_rate_of_return - this.hurdle_rate) / 4);
    if (this.actual_capital_available < 0) {
      this.actual_capital_available = 0;
    }
  } else {
    this.capital_scale_factor = (this.internal_rate_of_return - this.hurdle_rate) / 30.0;
    if (this.capital_scale_factor > 1) {
      this.capital_scale_factor = 1;
    }
    this.actual_capital_available = this.capital_available + (3 * this.capital_scale_factor);
  }
  if (this.actual_capital_available > 0) {
    this.deployment = (this.actual_capital_available * 1e9 / this.capital_cost) / 1000;
    this.energy_delivered = this.deployment * this.annualOutput / 1000;
    this.public_spend = this.energy_delivered * this.subsidy / 1000;
    this.total_profit = this.profit * this.deployment / 1000000;
  } else {
    this.deployment = 0;
    this.energy_delivered = 0;
    this.public_spend = 0;
    this.total_profit = 0;
  }
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