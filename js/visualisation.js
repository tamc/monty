var draw, histogram, normalZ, scatterplot;
normalZ = function(x, mean, standard_deviation) {
  var a;
  a = x - mean;
  return Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation);
};
histogram = function(tag, title, mean, standard_deviation, property) {
  var block_height, block_width, h, iteration_to_id, line, nesting_operator, p, points, svg, values_to_frequencies, values_to_ids, w, x, x_step, xrule, y, yrule;
  w = 200;
  h = 200;
  p = 30;
  x = d3.scale.linear().domain([0, 300]).range([0, w]);
  y = d3.scale.linear().domain([0, 20]).range([h, 0]);
  x_step = (x.domain()[1] - x.domain()[0]) / 50;
  nesting_operator = d3.nest().key(function(d) {
    return Math.round(property(d) / x_step) * x_step;
  });
  block_width = x(x_step) - x(0);
  block_height = h / (500 / 20);
  tag = d3.select(tag);
  tag.append("h2").text(title);
  svg = tag.append("svg:svg").attr("width", w + p * 2).attr("height", h + p * 2).append("svg:g").attr("transform", "translate(" + p + "," + p + ")");
  xrule = svg.selectAll("g.x").data(x.ticks(10)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", h);
  xrule.append("svg:text").attr("x", x).attr("y", h + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(x.tickFormat(10));
  yrule = svg.selectAll("g.y").data(y.ticks(10)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", w).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(function(d) {
    return y.tickFormat(10)(d) + "%";
  });
  svg.append("svg:rect").attr("width", w).attr("height", h + 1);
  points = x.ticks(100).map(function(d) {
    return {
      x: d,
      y: normalZ(d, mean, standard_deviation) * 1000
    };
  });
  line = d3.svg.line().x(function(d) {
    return x(d.x);
  }).y(function(d) {
    return y(d.y);
  });
  svg.append('svg:path').attr('class', 'distribution').attr('d', line(points));
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
    values.enter().append("svg:g").attr("class", "value").attr("transform", function(d) {
      return "translate(" + (x(+d.key)) + ",0)";
    });
    values.exit().remove();
    frequencies = values.selectAll("rect").data(values_to_frequencies, iteration_to_id);
    frequencies.classed('newblock', false);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block newblock block" + d.id;
    }).attr("y", function(d, i) {
      return y(i) - block_height;
    }).attr("width", block_width).attr("height", block_height).on('mouseover', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', true);
    }).on('mouseout', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', false);
    });
    return frequencies.exit().remove();
  };
  this.finished = function() {
    var frequencies;
    return frequencies = values.selectAll("rect").classed('newblock', false);
  };
  return this;
};
scatterplot = function(tag, title, x_low, x_high, y_low, y_high, x_property, y_property) {
  var block_height, block_width, h, iteration_to_id, p, svg, w, x, xrule, y, yrule;
  w = 250;
  h = 250;
  p = 20;
  x = d3.scale.linear().domain([x_low, x_high]).range([0, w]);
  y = d3.scale.linear().domain([y_low, y_high]).range([h, 0]);
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
  iteration_to_id = function(d) {
    return d.id;
  };
  block_width = 5;
  block_height = 5;
  this.update = function(data) {
    var frequencies;
    frequencies = svg.selectAll("rect.block").data(data, iteration_to_id);
    frequencies.classed('newblock', false);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block newblock block" + d.id;
    }).attr("x", function(d) {
      return x(x_property(d));
    }).attr("y", function(d) {
      return y(y_property(d)) - block_height;
    }).attr("width", block_width).attr("height", block_height).on('mouseover', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', true);
    }).on('mouseout', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', false);
    });
    return frequencies.exit().remove();
  };
  return this;
};
draw = function() {
  var charts, iterations, worker;
  charts = [
    new histogram("#capital", "Capital cost", 100, 20, function(d) {
      return d.technology.capital_cost;
    }), new histogram("#operating", "Operating cost", 100, 60, function(d) {
      return d.technology.operating_cost;
    }), new histogram("#fuel", "Fuel cost", 100, 60, function(d) {
      return d.technology.fuel_cost;
    }), new histogram("#output", "Output", 1, 0.3, function(d) {
      return d.technology.output;
    }), new histogram("#hurdle", "Hurdle rate", 0.1, 0.03, function(d) {
      return d.investors.hurdle_rate;
    }), new histogram("#quantity", "Investors", 100, 30, function(d) {
      return d.investors.quantity;
    }), new histogram("#price", "Price", 200, 60, function(d) {
      return d.environment.price;
    }), new histogram("#deployment", "Quantity deployed", 100, 60, function(d) {
      return d.deployment;
    }), new histogram("#energyDelivered", "Energy delivered", 100, 60, function(d) {
      return d.energyDelivered;
    }), new histogram("#publicSpend", "Public expenditure", 100, 60, function(d) {
      return d.publicSpend;
    }), new scatterplot('#spendEnergyDelivered', "Spend against energy delivered", 0, 3000, 0, 300, (function(d) {
      return d.publicSpend;
    }), (function(d) {
      return d.energyDelivered;
    })), new scatterplot('#energyPerPoundAgainstPounds', "Energy per pound of public spend against spend", 0, 3000, 0, 0.2, (function(d) {
      return d.publicSpend;
    }), (function(d) {
      return d.energyDelivered / d.publicSpend;
    }))
  ];
  iterations = [];
  worker = new Worker('../js/calculation.js');
  worker.onmessage = function(event) {
    var chart, _i, _len, _results;
    iterations.push(event.data);
    _results = [];
    for (_i = 0, _len = charts.length; _i < _len; _i++) {
      chart = charts[_i];
      _results.push(chart.update(iterations));
    }
    return _results;
  };
  worker.onerror = function(error) {
    console.log("Calculation error: " + error.message + "\n");
    throw error;
  };
  return worker.postMessage();
};