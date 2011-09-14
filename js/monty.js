var draw, environment, histogram, investors, iteration, randomNormalValue, randomValue, technology;
randomNormalValue = function() {
  return (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1);
};
randomValue = function(mean, standard_deviation, precision) {
  if (precision == null) {
    precision = 1;
  }
  return Math.round(((randomNormalValue() * standard_deviation) + mean) / precision) * precision;
};
technology = function() {
  this.capital_cost = randomValue(100, 20);
  this.operating_cost = randomValue(100, 60);
  this.fuel_cost = randomValue(100, 60);
  return this.output = randomValue(1, 0.3);
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
histogram = function(tag, data) {
  var block_height, block_width, buckets, frequencies, h, p, svg, values, w, x, xrule, y, yrule;
  w = 450;
  h = 450;
  p = 20;
  x = d3.scale.linear().domain([0, 200]).range([0, w]);
  y = d3.scale.linear().domain([0, 200]).range([h, 0]);
  svg = d3.select(tag).append("svg:svg").attr("width", w + p * 2).attr("height", h + p * 2).append("svg:g").attr("transform", "translate(" + p + "," + p + ")");
  xrule = svg.selectAll("g.x").data(x.ticks(10)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", h);
  xrule.append("svg:text").attr("x", x).attr("y", h + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(x.tickFormat(10));
  yrule = svg.selectAll("g.y").data(y.ticks(10)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", w).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(y.tickFormat(10));
  svg.append("svg:rect").attr("width", w).attr("height", h);
  buckets = d3.nest().key(function(d) {
    return d.technology.capital_cost;
  }).entries(data);
  values = svg.selectAll("g.values").data(buckets).enter().append("svg:g").attr("class", "value");
  block_width = x(1) - x(0);
  block_height = y(0) - y(1);
  return frequencies = values.selectAll("rect").data(function(d) {
    return d.values;
  }).enter().append("svg:rect").attr("class", "block").attr("x", function(d, i) {
    return x(d.technology.capital_cost);
  }).attr("y", function(d, i) {
    return y(i) - block_height;
  }).attr("width", block_width).attr("height", block_height);
};
draw = function() {
  var i, iterations;
  iterations = (function() {
    var _results;
    _results = [];
    for (i = 1; i <= 1000; i++) {
      _results.push(new iteration(new technology, new investors, new environment));
    }
    return _results;
  })();
  return new histogram("#histogram", iterations);
};