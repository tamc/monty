var cumulativeNormal, draw, erf, histogram, normalZ, probability_in_bin, scatterplot;
var __hasProp = Object.prototype.hasOwnProperty;
normalZ = function(x, mean, standard_deviation) {
  var a;
  a = x - mean;
  return Math.exp(-(a * a) / (2 * standard_deviation * standard_deviation)) / (Math.sqrt(2 * Math.PI) * standard_deviation);
};
erf = function(x) {
  var cof, d, dd, isneg, j, res, t, tmp, ty;
  cof = [-1.3026537197817094, 6.4196979235649026e-1, 1.9476473204185836e-2, -9.561514786808631e-3, -9.46595344482036e-4, 3.66839497852761e-4, 4.2523324806907e-5, -2.0278578112534e-5, -1.624290004647e-6, 1.303655835580e-6, 1.5626441722e-8, -8.5238095915e-8, 6.529054439e-9, 5.059343495e-9, -9.91364156e-10, -2.27365122e-10, 9.6467911e-11, 2.394038e-12, -6.886027e-12, 8.94487e-13, 3.13092e-13, -1.12708e-13, 3.81e-16, 7.106e-15, -1.523e-15, -9.4e-17, 1.21e-16, -2.8e-17];
  j = cof.length - 1;
  isneg = false;
  d = 0;
  dd = 0;
  if (x < 0) {
    x = -x;
    isneg = true;
  }
  t = 2 / (2 + x);
  ty = 4 * t - 2;
  while (j > 0) {
    tmp = d;
    d = ty * d - dd + cof[j];
    dd = tmp;
    j--;
  }
  res = t * Math.exp(-x * x + 0.5 * (cof[0] + ty * d) - dd);
  if (isneg) {
    return res - 1;
  } else {
    return 1 - res;
  }
};
cumulativeNormal = function(x, mean, standard_deviation) {
  return 0.5 * (1 + erf((x - mean) / (Math.sqrt(2) * standard_deviation)));
};
probability_in_bin = function(bin, mean, standard_deviation, bin_width) {
  return cumulativeNormal(bin + (bin_width / 2), mean, standard_deviation) - cumulativeNormal(bin - (bin_width / 2), mean, standard_deviation);
};
histogram = function(opts) {
  var block_height, block_width, iteration_to_id, key, line, nesting_operator, point_group, points, svg, tag, value, values_to_frequencies, values_to_ids, x, x_step, xrule, y, yrule, _ref;
  if (opts == null) {
    opts = {};
  }
  _ref = histogram.defaults;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    if (opts[key] == null) {
      opts[key] = value;
    }
  }
  x = d3.scale.linear().domain([opts.x_min, opts.x_max]).range([0, opts.width]);
  y = d3.scale.linear().domain([opts.y_min, opts.y_max]).range([opts.height, 0]);
  x_step = (x.domain()[1] - x.domain()[0]) / opts.bins;
  nesting_operator = d3.nest().key(function(d) {
    return Math.round(opts.property(d) / x_step) * x_step;
  });
  block_width = x(x_step) - x(0);
  block_height = opts.height / ((opts.y_max / 100) * 500);
  tag = d3.select(opts.tag);
  tag.append("h2").text(opts.title);
  svg = tag.append("svg:svg").attr("width", opts.width + opts.padding * 2).attr("height", opts.height + opts.padding * 2).append("svg:g").attr("transform", "translate(" + opts.padding + "," + opts.padding + ")");
  xrule = svg.selectAll("g.x").data(x.ticks(opts.x_ticks)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", opts.height);
  xrule.append("svg:text").attr("x", x).attr("y", opts.height + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(x.tickFormat(opts.x_ticks));
  yrule = svg.selectAll("g.y").data(y.ticks(opts.y_ticks)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", opts.width).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(function(d) {
    return y.tickFormat(opts.x_ticks)(d) + "%";
  });
  point_group = svg.append("svg:g");
  if ((opts.mean != null) && (opts.standard_deviation != null)) {
    points = x.ticks(100).map(function(d) {
      return {
        x: d,
        y: probability_in_bin(d, opts.mean, opts.standard_deviation, x_step) * 100
      };
    });
    line = d3.svg.line().x(function(d) {
      return x(d.x);
    }).y(function(d) {
      return y(d.y);
    });
    svg.append('svg:path').attr('class', 'distribution').attr('d', line(points));
  }
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
    values = point_group.selectAll("g.value").data(buckets, values_to_ids);
    values.enter().append("svg:g").attr("class", "value").attr("transform", function(d) {
      return "translate(" + (x(+d.key - (x_step / 2))) + ",0)";
    });
    values.exit().remove();
    frequencies = values.selectAll("rect").data(values_to_frequencies, iteration_to_id);
    frequencies.classed('selected', false);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block selected block" + d.id;
    }).attr("y", function(d, i) {
      return opts.height - ((i + 1) * block_height);
    }).attr("width", block_width).attr("height", block_height).on('mouseover', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', true);
    }).on('mouseout', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', false);
    });
    return frequencies.exit().remove();
  };
  return this;
};
histogram.defaults = {
  tag: "body",
  width: 250,
  height: 250,
  padding: 30,
  x_min: 0,
  x_max: 300,
  y_min: 0,
  y_max: 10,
  x_ticks: 10,
  y_ticks: 10,
  property: function(d) {
    return d;
  },
  bins: 50,
  title: "Histogram"
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
    new histogram({
      tag: '#capital',
      title: "Capital cost",
      mean: 100,
      standard_deviation: 30,
      property: function(d) {
        return d.technology.capital_cost;
      }
    }), new histogram({
      tag: "#capital",
      title: "Capital cost",
      mean: 100,
      standard_deviation: 20,
      property: function(d) {
        return d.technology.capital_cost;
      }
    }), new histogram({
      tag: "#operating",
      title: "Operating cost",
      mean: 100,
      standard_deviation: 50,
      property: function(d) {
        return d.technology.operating_cost;
      }
    }), new histogram({
      tag: "#fuel",
      title: "Fuel cost",
      mean: 100,
      standard_deviation: 50,
      property: function(d) {
        return d.technology.fuel_cost;
      }
    }), new histogram({
      tag: "#output",
      title: "Output",
      mean: 1,
      standard_deviation: 0.3,
      property: (function(d) {
        return d.technology.output;
      }),
      x_max: 2
    }), new histogram({
      tag: "#hurdle",
      title: "Hurdle rate",
      mean: 10,
      standard_deviation: 3,
      property: (function(d) {
        return d.investors.hurdle_rate * 100;
      }),
      x_max: 20
    }), new histogram({
      tag: "#quantity",
      title: "Investors",
      mean: 100,
      standard_deviation: 30,
      property: function(d) {
        return d.investors.quantity;
      }
    }), new histogram({
      tag: "#price",
      title: "Price",
      mean: 200,
      standard_deviation: 60,
      property: function(d) {
        return d.environment.price;
      }
    }), new histogram({
      tag: "#deployment",
      title: "Quantity deployed",
      property: function(d) {
        return d.deployment;
      }
    }), new histogram({
      tag: "#energyDelivered",
      title: "Energy delivered",
      property: function(d) {
        return d.energyDelivered;
      }
    }), new histogram({
      tag: "#publicSpend",
      title: "Public expenditure",
      x_max: 2000,
      property: function(d) {
        return d.publicSpend;
      }
    }), new scatterplot('#spendEnergyDelivered', "Spend against energy delivered", 0, 2000, 0, 300, (function(d) {
      return d.publicSpend;
    }), (function(d) {
      return d.energyDelivered;
    })), new scatterplot('#energyPerPoundAgainstPounds', "Energy per pound of public spend against spend", 0, 2000, 0, 0.2, (function(d) {
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