var environment, investors, iteration, randomNormalValue, randomValue, technology;
randomNormalValue = function() {
  return (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1);
};
randomValue = function(mean, standard_deviation) {
  return (randomNormalValue() * standard_deviation) + mean;
};
technology = function() {
  this.capital_cost = randomValue(100, 60);
  this.operating_cost = randomValue(100, 60);
  this.fuel_cost = randomValue(100, 60);
  return this.output = randomValue(1, 0.3);
};
investors = function() {
  this.hurdle_rate = randomValue(0.1, 0.01);
  this.loan_period = 10;
  return this.quantity = randomValue(100, 30);
};
environment = function() {
  this.subsidy = 10;
  return this.price = randomValue(200, 60);
};
iteration = function(technology, investors, environment) {
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
  this.publicSpend = this.deployment * this.environment.subsidy;
  this.energyDelivered = this.deployment * this.technology.output;
  return this;
};