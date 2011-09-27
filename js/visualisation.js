var charts, clear, cumulativeNormal, defaults, distributions, erf, histogram, inverse_probability_in_mean_bin, iterations, normalZ, probability_in_bin, running, scatterplot, setup, start, stop, worker;
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
inverse_probability_in_mean_bin = function(probability, mean, bin_width, guess_step, standard_deviation_guess) {
  var error;
  if (guess_step == null) {
    guess_step = bin_width;
  }
  if (standard_deviation_guess == null) {
    standard_deviation_guess = 0.0;
  }
  while (probability_in_bin(mean, mean, standard_deviation_guess, bin_width) > probability) {
    standard_deviation_guess = standard_deviation_guess + guess_step;
  }
  error = probability - probability_in_bin(mean, mean, standard_deviation_guess, bin_width);
  if (error > 0.001) {
    return inverse_probability_in_mean_bin(probability, mean, bin_width, guess_step / 10, standard_deviation_guess - guess_step);
  } else {
    return standard_deviation_guess;
  }
};
histogram = function(opts) {
  var block_height, block_width, click_rect, distribution_move, empty, iteration_to_id, key, nesting_operator, point_group, stickySelected, svg, tag, that, value, values_to_frequencies, values_to_ids, x, x_step, xrule, y, yrule, _ref;
  this.opts = opts != null ? opts : {};
  _ref = histogram.defaults;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    if (this.opts[key] == null) {
      this.opts[key] = value;
    }
  }
  that = this;
  x = d3.scale.linear().domain([this.opts.x_min, this.opts.x_max]).range([0, this.opts.width]);
  y = d3.scale.linear().domain([this.opts.y_min, this.opts.y_max]).range([this.opts.height, 0]);
  x_step = (x.domain()[1] - x.domain()[0]) / this.opts.bins;
  nesting_operator = d3.nest().key(function(d) {
    return Math.round(that.opts.property(d) / x_step) * x_step;
  });
  block_width = x(x_step) - x(0);
  block_height = (this.opts.height / this.opts.y_max) / 5;
  tag = d3.select(this.opts.tag);
  if (this.opts.title != null) {
    tag.append("h2").text(this.opts.title);
  }
  svg = tag.append("svg:svg").attr("width", this.opts.width + this.opts.padding * 2).attr("height", this.opts.height + this.opts.padding * 2).append("svg:g").attr("class", "main").attr("transform", "translate(" + this.opts.padding + "," + this.opts.padding + ")");
  click_rect = svg.append("svg:rect").attr("class", "click").attr("x", 0).attr("y", 0).attr("width", this.opts.width).attr("height", this.opts.height);
  xrule = svg.selectAll("g.x").data(x.ticks(this.opts.x_ticks)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", this.opts.height);
  xrule.append("svg:text").attr("x", x).attr("y", this.opts.height + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(function(d) {
    return x.tickFormat(that.opts.x_ticks)(d) + that.opts.x_axis_suffix;
  });
  if (this.opts.x_axis_title != null) {
    svg.append("svg:text").attr("x", this.opts.width / 2).attr("y", this.opts.height + 18).attr("dy", ".71em").attr("text-anchor", "middle").text(this.opts.x_axis_title);
  }
  yrule = svg.selectAll("g.y").data(y.ticks(this.opts.y_ticks)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", this.opts.width).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(function(d) {
    return y.tickFormat(that.opts.y_ticks)(d) + that.opts.y_axis_suffix;
  });
  if (this.opts.y_axis_title != null) {
    svg.append("svg:text").attr("x", -this.opts.height / 2).attr("y", this.opts.width / 2).attr("dy", ".31em").attr("text-anchor", "middle").attr("transform", "rotate(-90)translate(0,-" + ((this.opts.width / 2) + 30) + ")").text(this.opts.y_axis_title);
  }
  point_group = svg.append("svg:g");
  stickySelected = false;
  point_group.on('mousedown', function(d) {
    stickySelected = true;
    return d3.event.preventDefault();
  });
  point_group.on('mouseup', function(d) {
    return stickySelected = false;
  });
  empty = true;
  distribution_move = function(d) {
    var m;
    if (empty !== true) {
      return;
    }
    m = d3.svg.mouse(svg.node());
    that.opts.mean = x.invert(m[0]);
    that.opts.standard_deviation = inverse_probability_in_mean_bin(y.invert(m[1]) / 100, that.opts.mean, x_step);
    that.drawDistributionLine();
    return d3.event.preventDefault();
  };
  this.allow_distribution_to_be_altered = function() {
    return click_rect.on('click', distribution_move);
  };
  this.drawDistributionLine = function() {
    var curve, line, points;
    if (!((that.opts.mean != null) && (that.opts.standard_deviation != null))) {
      return;
    }
    line = d3.svg.line().x(function(d) {
      return x(d.x);
    }).y(function(d) {
      return y(d.y);
    });
    points = x.ticks(100).map(function(d) {
      return {
        x: d,
        y: probability_in_bin(d, that.opts.mean, that.opts.standard_deviation, x_step) * 100
      };
    });
    curve = svg.selectAll('path.distribution').data([points]);
    curve.enter().append('svg:path').attr('class', 'distribution');
    curve.transition().duration(500).attr('d', line);
    return curve.on;
  };
  this.drawDistributionLine();
  values_to_ids = function(d) {
    return d.key;
  };
  values_to_frequencies = function(d) {
    return d.values;
  };
  iteration_to_id = function(d) {
    return +d.id;
  };
  this.clear = function() {
    point_group.selectAll("g.value").remove();
    return empty = true;
  };
  this.update = function(data) {
    var buckets, frequencies, values;
    empty = false;
    buckets = nesting_operator.entries(data);
    values = point_group.selectAll("g.value").data(buckets, values_to_ids);
    values.enter().append("svg:g").attr("class", "value").attr("transform", function(d) {
      return "translate(" + (x(+d.key - (x_step / 2))) + ",0)";
    });
    values.exit().remove();
    frequencies = values.selectAll("rect").data(values_to_frequencies, iteration_to_id);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block block" + d.id;
    }).attr("y", function(d, i) {
      return that.opts.height - ((i + 1) * block_height);
    }).attr("width", block_width).attr("height", block_height).on('mouseover', function(d) {
      return d3.selectAll(".block" + d.id).classed("selected", true).style("fill", "yellow");
    }).on('mouseout', function(d) {
      if (stickySelected === true) {
        return;
      }
      return d3.selectAll("rect.selected").classed("selected", false).style("fill", "grey");
    }).style("fill", "yellow").transition().duration(1000).style("fill", "grey");
    return frequencies.exit().remove();
  };
  return this;
};
scatterplot = function(opts) {
  var block_height, block_width, iteration_to_id, key, point_group, stickySelected, svg, tag, that, value, x, xrule, y, yrule, _ref;
  this.opts = opts != null ? opts : {};
  _ref = scatterplot.defaults;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    if (this.opts[key] == null) {
      this.opts[key] = value;
    }
  }
  that = this;
  x = d3.scale.linear().domain([this.opts.x_min, this.opts.x_max]).range([0, this.opts.width]);
  y = d3.scale.linear().domain([this.opts.y_min, this.opts.y_max]).range([this.opts.height, 0]);
  tag = d3.select(this.opts.tag);
  if (this.opts.title != null) {
    tag.append("h2").text(this.opts.title);
  }
  svg = tag.append("svg:svg").attr("width", this.opts.width + this.opts.padding * 2).attr("height", this.opts.height + this.opts.padding * 2).append("svg:g").attr("transform", "translate(" + this.opts.padding + "," + this.opts.padding + ")");
  xrule = svg.selectAll("g.x").data(x.ticks(this.opts.x_ticks)).enter().append("svg:g").attr("class", "x");
  xrule.append("svg:line").attr("x1", x).attr("x2", x).attr("y1", 0).attr("y2", this.opts.height);
  xrule.append("svg:text").attr("x", x).attr("y", this.opts.height + 3).attr("dy", ".71em").attr("text-anchor", "middle").text(function(d) {
    return x.tickFormat(that.opts.x_ticks)(d) + that.opts.x_axis_suffix;
  });
  if (this.opts.x_axis_title != null) {
    svg.append("svg:text").attr("x", this.opts.width / 2).attr("y", this.opts.height + 18).attr("dy", ".71em").attr("text-anchor", "middle").text(this.opts.x_axis_title);
  }
  yrule = svg.selectAll("g.y").data(y.ticks(this.opts.y_ticks)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", this.opts.width).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(function(d) {
    return y.tickFormat(that.opts.y_ticks)(d) + that.opts.y_axis_suffix;
  });
  if (this.opts.y_axis_title != null) {
    svg.append("svg:text").attr("x", -this.opts.height / 2).attr("y", this.opts.width / 2).attr("dy", ".31em").attr("text-anchor", "middle").attr("transform", "rotate(-90)translate(0,-" + ((this.opts.width / 2) + 30) + ")").text(this.opts.y_axis_title);
  }
  point_group = svg.append("svg:g");
  stickySelected = false;
  point_group.on('mousedown', function(d) {
    d3.selectAll("rect.stickySelected").classed('stickySelected', false);
    return stickySelected = true;
  });
  point_group.on('mouseup', function(d) {
    return stickySelected = false;
  });
  iteration_to_id = function(d) {
    return d.id;
  };
  block_width = 5;
  block_height = 5;
  this.clear = function() {
    return point_group.selectAll("rect.block").remove();
  };
  this.update = function(data) {
    var frequencies;
    frequencies = point_group.selectAll("rect.block").data(data, iteration_to_id);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block block" + d.id;
    }).attr("x", function(d) {
      return x(that.opts.x_property(d));
    }).attr("y", function(d) {
      return y(that.opts.y_property(d)) - block_height;
    }).attr("width", block_width).attr("height", block_height).on('mouseover', function(d) {
      d3.selectAll("rect.selected").classed('selected', false);
      if (stickySelected === true) {
        return d3.selectAll(".block" + d.id).classed('stickySelected', true);
      } else {
        return d3.selectAll(".block" + d.id).classed('selected', true);
      }
    }).on('mouseout', function(d) {
      return d3.selectAll(".block" + d.id).classed('selected', false);
    }).style("fill", "yellow").transition().duration(1000).style("fill", "grey");
    return frequencies.exit().remove();
  };
  return this;
};
histogram.defaults = {
  tag: "body",
  width: 250,
  height: 250,
  padding: 35,
  x_min: 0,
  x_max: 300,
  y_min: 0,
  y_max: 20,
  x_ticks: 10,
  y_ticks: 10,
  property: function(d) {
    return d;
  },
  bins: 50,
  title: null,
  x_axis_suffix: "",
  x_axis_title: null,
  y_axis_suffix: "%",
  y_axis_title: "Probability"
};
scatterplot.defaults = {
  tag: "body",
  width: 250,
  height: 250,
  padding: 35,
  x_min: 0,
  x_max: 300,
  y_min: 0,
  y_max: 10,
  x_ticks: 10,
  y_ticks: 10,
  x_property: function(d) {
    return d;
  },
  y_property: function(d) {
    return d;
  },
  title: null,
  x_axis_suffix: "",
  x_axis_title: null,
  y_axis_suffix: "",
  y_axis_title: null
};
defaults = {
  "subsidy": {
    "mean": 100,
    "sd": 0
  },
  "capital_cost": {
    "mean": 3700,
    "sd": 3700 - 2900
  },
  "operating_cost": {
    "mean": 78,
    "sd": 78 - 64
  },
  "fuel_cost": {
    "mean": 0,
    "sd": 0
  },
  "efficiency": {
    "mean": 95,
    "sd": 2
  },
  "availability": {
    "mean": 86,
    "sd": 4
  },
  "economic_life": {
    "mean": 60,
    "sd": 10
  },
  "hurdle_rate": {
    "mean": 10,
    "sd": 3
  },
  "capital_available": {
    "mean": 5,
    "sd": 1
  },
  "price": {
    "mean": 50,
    "sd": 10
  }
};
charts = {};
iterations = [];
running = false;
worker = null;
setup = function() {
  var chart, name, values;
  charts['subsidy'] = new histogram({
    tag: '#subsidy',
    x_axis_title: "Subsidy (£/MWh)",
    x_max: 400,
    property: function(d) {
      return d.subsidy;
    }
  });
  charts['capital_cost'] = new histogram({
    tag: '#capital',
    x_axis_title: "Capital cost (£/kW)",
    x_max: 7500,
    property: function(d) {
      return d.capital_cost;
    }
  });
  charts['operating_cost'] = new histogram({
    tag: "#operating",
    x_axis_title: "Operating cost (£/kW/yr)",
    property: function(d) {
      return d.operating_cost;
    }
  });
  charts['fuel_cost'] = new histogram({
    tag: "#fuel",
    x_axis_title: "Fuel cost (£/MWh)",
    property: function(d) {
      return d.fuel_cost;
    }
  });
  charts['efficiency'] = new histogram({
    tag: "#efficiency",
    x_axis_title: "Efficiency",
    x_axis_suffix: "%",
    x_max: 100,
    property: function(d) {
      return d.efficiency;
    }
  });
  charts['availability'] = new histogram({
    tag: "#availability",
    x_axis_title: "Availability or capacity factor (% of hours operating)",
    x_axis_suffix: "%",
    x_max: 100,
    property: function(d) {
      return d.availability;
    }
  });
  charts['economic_life'] = new histogram({
    tag: "#life",
    x_axis_title: "Economic life (years)",
    x_max: 100,
    property: function(d) {
      return d.economic_life;
    }
  });
  charts['hurdle_rate'] = new histogram({
    tag: "#hurdle",
    x_axis_title: "Investor's hurdle rate (apr)",
    x_axis_suffix: "%",
    x_max: 20,
    property: function(d) {
      return d.hurdle_rate;
    }
  });
  charts['capital_available'] = new histogram({
    tag: "#quantity",
    x_axis_title: "Investor's capital available £bn",
    x_max: 10,
    property: function(d) {
      return d.capital_available;
    }
  });
  charts['cost_per_MWh'] = new histogram({
    tag: "#annualcost",
    x_axis_title: "Cost £/MWh",
    x_max: 300,
    property: function(d) {
      return d.cost_per_MWh;
    }
  });
  charts['price'] = new histogram({
    tag: "#price",
    x_axis_title: "Price of electricity £/MWh",
    property: function(d) {
      return d.price;
    }
  });
  charts['deployment'] = new histogram({
    tag: "#deployment",
    x_axis_title: "Quantity deployed MW",
    x_max: 3000,
    property: function(d) {
      return d.deployment;
    }
  });
  charts['energy_delivered'] = new histogram({
    tag: "#energyDelivered",
    x_axis_title: "Energy delivered TWh",
    x_max: 50,
    property: function(d) {
      return d.energyDelivered;
    }
  });
  charts['public_spend'] = new histogram({
    tag: "#publicSpend",
    x_axis_title: "Public expenditure £bn",
    x_max: 5,
    property: function(d) {
      return d.publicSpend;
    }
  });
  charts['public_spend_against_energy'] = new scatterplot({
    tag: '#spendEnergyDelivered',
    x_axis_title: "Public expenditure £bn",
    y_axis_title: "Energy delivered TWh",
    x_max: 5,
    y_max: 50,
    x_property: (function(d) {
      return d.publicSpend;
    }),
    y_property: (function(d) {
      return d.energyDelivered;
    })
  });
  charts['energy_per_public_spend_against_public_spend'] = new scatterplot({
    tag: '#energyPerPoundAgainstPounds',
    x_axis_title: "Public expenditure £",
    y_axis_title: "Energy per pound of public spend MWh/£",
    x_max: 5,
    y_max: 20,
    x_property: (function(d) {
      return d.publicSpend;
    }),
    y_property: (function(d) {
      return d.energyDelivered / d.publicSpend;
    })
  });
  for (name in defaults) {
    if (!__hasProp.call(defaults, name)) continue;
    values = defaults[name];
    chart = charts[name];
    chart.opts.mean = values.mean;
    chart.opts.standard_deviation = values.sd;
    chart.drawDistributionLine();
    chart.allow_distribution_to_be_altered();
  }
  d3.select("#oneRun").on('click', function() {
    start(1);
    return false;
  });
  d3.select("#tenRuns").on('click', function() {
    start(10);
    return false;
  });
  d3.select("#hundredRuns").on('click', function() {
    start(100);
    return false;
  });
  d3.select("#fiveHundredRuns").on('click', function() {
    start(500);
    return false;
  });
  d3.select("#stopButton").on('click', function() {
    stop();
    return false;
  });
  return d3.select("#clearButton").on('click', function() {
    clear();
    return false;
  });
};
distributions = function() {
  var chart, name, parameters;
  parameters = {};
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    if ((chart.opts.mean != null) && (chart.opts.standard_deviation != null)) {
      parameters[name] = {
        mean: chart.opts.mean,
        sd: chart.opts.standard_deviation
      };
    }
  }
  return parameters;
};
stop = function() {
  if (running !== true) {
    return;
  }
  running = false;
  return worker.terminate();
};
start = function(number_of_iterations) {
  if (number_of_iterations == null) {
    number_of_iterations = 500;
  }
  stop();
  d3.selectAll("rect.selected").classed('selected', false);
  worker = new Worker('../js/calculation.js');
  running = true;
  worker.onmessage = function(event) {
    var chart, name;
    iterations.push(event.data);
    for (name in charts) {
      if (!__hasProp.call(charts, name)) continue;
      chart = charts[name];
      chart.update(iterations);
    }
    return d3.select("#message}").text("" + iterations.length + " runs completed");
  };
  worker.onerror = function(error) {
    console.log("Calculation error: " + error.message + "\n");
    throw error;
  };
  console.log(distributions());
  return worker.postMessage({
    starting_id: iterations.length,
    number_of_iterations: number_of_iterations,
    distributions: distributions()
  });
};
clear = function() {
  var chart, name;
  stop();
  iterations = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    chart.clear();
  }
  return d3.select("#message}").text("");
};