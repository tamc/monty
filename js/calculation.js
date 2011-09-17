var environment, investors, iteration, normalZ, randomNormalValue, randomValue, technology;
randomNormalValue = function() {
  return (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1);
};
randomValue = function(mean, standard_deviation, precision) {
  if (precision == null) {
    precision = 1;
  }
  return Math.round(((randomNormalValue() * standard_deviation) + mean) / precision) * precision;
};
normalZ = function(x, mean, standard_deviation) {
  var a;
  a = x - Mean;
  return Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation);
};
technology = function() {
  this.capital_cost = randomValue(100, 20);
  this.operating_cost = randomValue(100, 60);
  this.fuel_cost = randomValue(100, 60);
  return this.output = randomValue(1, 0.3, 0.1);
};
investors = function() {
  this.hurdle_rate = randomValue(0.1, 0.03, 0.01);
  this.loan_period = 10;
  return this.quantity = randomValue(100, 30);
};
environment = function() {
  this.subsidy = 10;
  return this.price = randomValue(200, 60);
};
iteration = function(id, technology, investors, environment) {
  this.id = id;
  this.technology = technology;
  this.investors = investors;
  this.environment = environment;
  this.isTechnologyBuilt = function() {
    return this.annualIncome() > this.annualCost();
  };
  this.annualIncome = function() {
    return this.technology.output * (this.environment.price + this.environment.subsidy);
  };
  this.annualCost = function() {
    return this.technology.fuel_cost + this.technology.operating_cost + this.annualCapitalCost();
  };
  this.annualCapitalCost = function() {
    return this.technology.capital_cost * this.investors.hurdle_rate * Math.pow(1 + this.investors.hurdle_rate, this.investors.loan_period) / (Math.pow(1 + this.investors.hurdle_rate, this.investors.loan_period) - 1);
  };
  this.deployment = this.isTechnologyBuilt() * this.investors.quantity;
  this.energyDelivered = this.deployment * this.technology.output;
  this.publicSpend = this.deployment * this.environment.subsidy;
  return this;
};
this.onmessage = function(data) {
  var i;
  for (i = 1; i <= 500; i++) {
    this.postMessage(new iteration(i, new technology, new investors, new environment));
    false;
  }
  return this.close;
};