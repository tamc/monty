var draw, histogram;
histogram = function(tag, title, mean, standard_deviation, property) {
  var block_height, block_width, h, iteration_to_id, nesting_operator, p, svg, values_to_frequencies, values_to_ids, w, x, xrule, y, yrule;
  w = 250;
  h = 250;
  p = 20;
  x = d3.scale.linear().domain([mean - 3 * standard_deviation, mean + 3 * standard_deviation]).range([0, w]);
  y = d3.scale.linear().domain([0, 0.2 * 200]).range([h, 0]);
  tag = d3.select(tag);
  tag.append("h2").text(title);
  svg = tag.append("svg:svg").attr("width", w + p * 2).attr("height", h + p * 2).append("svg:g").attr("transform", "translate(" + p + "," + p + ")");
  xrule = svg.selectAll("g.x").data(x.ticks(10)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", h);
  xrule.append("svg:text").attr("x", x).attr("y", h + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(x.tickFormat(10));
  yrule = svg.selectAll("g.y").data(y.ticks(10)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", w).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(y.tickFormat(10));
  svg.append("svg:rect").attr("width", w).attr("height", h + 1);
  nesting_operator = d3.nest().key(property);
  block_width = x(1) - x(0);
  block_height = y(0) - y(1);
  values_to_ids = function(d) {
    return d.key;
  };
  values_to_frequencies = function(d) {
    return d.values;
  };
  iteration_to_id = function(d) {
    return +d.id;
  };
  this.update = function(data) {
    var buckets, frequencies, values;
    buckets = nesting_operator.entries(data);
    values = svg.selectAll("g.value").data(buckets, values_to_ids);
    values.enter().append("svg:g").attr("class", "value");
    values.exit().remove();
    frequencies = values.selectAll("rect").data(values_to_frequencies, iteration_to_id);
    frequencies.classed('newblock', false);
    frequencies.enter().append("svg:rect").classed("block", true).classed('newblock', true).attr("x", function(d, i) {
      return x(property(d));
    }).attr("y", function(d, i) {
      return y(i) - block_height;
    }).attr("width", block_width).attr("height", block_height);
    return frequencies.exit().remove();
  };
  return this;
};
draw = function() {
  var histograms, iterations, worker;
  histograms = [
    new histogram("#capital", "Capital cost", 100, 20, function(d) {
      return d.technology.capital_cost;
    }), new histogram("#operating", "Operating cost", 100, 60, function(d) {
      return d.technology.operating_cost;
    }), new histogram("#fuel", "Fuel cost", 100, 60, function(d) {
      return d.technology.fuel_cost;
    }), new histogram("#output", "Output", 100, 60, function(d) {
      return d.technology.output;
    }), new histogram("#hurdle", "Hurdle rate", 0.1, 0.03, function(d) {
      return d.investors.hurdle_rate;
    }), new histogram("#quantity", "Investors", 100, 60, function(d) {
      return d.investors.quantity;
    }), new histogram("#price", "Price", 100, 60, function(d) {
      return d.environment.price;
    }), new histogram("#deployment", "Quantity deployed", 100, 60, function(d) {
      return d.deployment;
    }), new histogram("#energyDelivered", "Energy delivered", 100, 60, function(d) {
      return d.energyDelivered;
    }), new histogram("#publicSpend", "Public expenditure", 100, 60, function(d) {
      return d.publicSpend;
    })
  ];
  iterations = [];
  worker = new Worker('../js/calculation.js');
  worker.onmessage = function(event) {
    var histogram, _i, _len, _results;
    iterations.push(event.data);
    _results = [];
    for (_i = 0, _len = histograms.length; _i < _len; _i++) {
      histogram = histograms[_i];
      _results.push(histogram.update(iterations));
    }
    return _results;
  };
  worker.onerror = function(error) {
    console.log("Calculation error: " + error.message + "\n");
    throw error;
  };
  return worker.postMessage();
};