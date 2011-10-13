var charts, clear, defaults, distributionUpdated, distributions, iteration, medians, running, setToDefaults, setup, start, stop, worker;
var __hasProp = Object.prototype.hasOwnProperty;
slider.defaults = {
  tag: "body",
  width: 250,
  height: 125,
  padding: 35,
  x_min: 0,
  x_max: 300,
  y_min: 0,
  y_max: 20,
  x_ticks: 10,
  y_ticks: 5,
  property: function(d) {
    return d;
  },
  attempts: 500,
  bins: 50,
  title: null,
  x_axis_suffix: "",
  x_axis_title: null
};
scatterplot.defaults = {
  tag: "body",
  width: 500,
  height: 500,
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
    distribution: 'fixed',
    "value": 94
  },
  "capital_cost": {
    distribution: 'normal',
    "mean": 2211,
    "sd": 2211 - 1756
  },
  "operating_cost": {
    distribution: 'normal',
    "mean": 132,
    "sd": (132 - 81) / 2
  },
  "fuel_cost": {
    distribution: 'fixed',
    "value": 0
  },
  "efficiency": {
    distribution: 'fixed',
    "value": 100
  },
  "availability": {
    distribution: 'normal',
    "mean": 30,
    "sd": 7
  },
  "economic_life": {
    distribution: 'normal',
    "mean": 25,
    "sd": 7
  },
  "hurdle_rate": {
    distribution: 'normal',
    "mean": 13,
    "sd": 2
  },
  "capital_available": {
    distribution: 'normal',
    "mean": 17,
    "sd": 5
  },
  "price": {
    distribution: 'normal',
    "mean": 71,
    "sd": (71 - 41) / 3
  }
};
charts = {};
iteration = [];
running = false;
worker = null;
setup = function() {
  charts = {};
  charts['capital_cost'] = new slider({
    tag: '#capital',
    x_axis_title: "Capital cost (£/kW)",
    x_max: 7500,
    property: function(d) {
      return d.capital_cost;
    }
  });
  charts['operating_cost'] = new slider({
    tag: "#operating",
    x_axis_title: "Operating cost (£/kW/yr)",
    property: function(d) {
      return d.operating_cost;
    }
  });
  charts['availability'] = new slider({
    tag: "#availability",
    x_axis_title: "Capacity factor (% of peak output that are actually delivered)",
    x_axis_suffix: "%",
    x_max: 100,
    property: function(d) {
      return d.availability;
    }
  });
  charts['economic_life'] = new slider({
    tag: "#life",
    x_axis_title: "Economic life (years)",
    x_max: 100,
    property: function(d) {
      return d.economic_life;
    }
  });
  charts['hurdle_rate'] = new slider({
    tag: "#hurdle",
    x_axis_title: "Investor's hurdle rate (apr)",
    x_axis_suffix: "%",
    x_max: 20,
    property: function(d) {
      return d.hurdle_rate;
    }
  });
  charts['capital_available'] = new slider({
    tag: "#quantity",
    x_axis_title: "Investor's capital available £bn",
    x_max: 50,
    property: function(d) {
      return d.capital_available;
    }
  });
  charts['price'] = new slider({
    tag: "#price",
    x_axis_title: "Price of electricity £/MWh",
    property: function(d) {
      return d.price;
    }
  });
  charts['energy_delivered'] = new slider({
    tag: "#energyDelivered",
    x_axis_title: "Energy delivered TWh",
    x_max: 70,
    width: 500,
    height: 250,
    property: function(d) {
      return d.energyDelivered;
    }
  });
  charts['public_spend'] = new slider({
    tag: "#publicSpend",
    x_axis_title: "Public expenditure £bn",
    x_max: 7,
    width: 500,
    height: 250,
    property: function(d) {
      return d.publicSpend;
    }
  });
  setToDefaults();
  slider.prototype.distributionUpdated = distributionUpdated;
  return distributionUpdated();
};
distributionUpdated = function() {
  stop();
  worker = new Worker('../js/calculation.js');
  worker.onmessage = function(event) {
    var chart, name, _results;
    console.log("Calculated results");
    console.log(event.data);
    _results = [];
    for (name in charts) {
      if (!__hasProp.call(charts, name)) continue;
      chart = charts[name];
      _results.push(chart.showMedianForDatum(event.data));
    }
    return _results;
  };
  return worker.postMessage({
    starting_id: 1,
    number_of_iterations: 1,
    distributions: medians()
  });
};
setToDefaults = function() {
  var chart, name, values, _results;
  _results = [];
  for (name in defaults) {
    if (!__hasProp.call(defaults, name)) continue;
    values = defaults[name];
    chart = charts[name];
    _results.push(chart != null ? (chart.opts.mean = values.mean, chart.opts.standard_deviation = values.sd, chart.drawDistributionLine(), chart.allow_distribution_to_be_altered()) : void 0);
  }
  return _results;
};
medians = function() {
  var chart, defaultDistribution, name, parameters;
  parameters = {};
  for (name in defaults) {
    if (!__hasProp.call(defaults, name)) continue;
    defaultDistribution = defaults[name];
    chart = charts[name];
    if (chart != null) {
      parameters[name] = {
        distribution: 'fixed',
        value: chart.opts.mean
      };
    } else if (defaultDistribution.value != null) {
      parameters[name] = {
        distribution: 'fixed',
        value: defaultDistribution.value
      };
    } else if (defaultDistribution.mean != null) {
      parameters[name] = {
        distribution: 'fixed',
        value: defaultDistribution.mean
      };
    }
  }
  return parameters;
};
distributions = function() {
  var chart, defaultDistribution, name, parameters;
  parameters = {};
  for (name in defaults) {
    if (!__hasProp.call(defaults, name)) continue;
    defaultDistribution = defaults[name];
    chart = charts[name];
    if (chart != null) {
      parameters[name] = chart.distribution();
    } else {
      parameters[name] = defaultDistribution;
    }
  }
  console.log(parameters);
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
  return worker.postMessage({
    starting_id: iterations.length,
    number_of_iterations: number_of_iterations,
    distributions: distributions()
  });
};
clear = function() {
  var chart, iterations, name;
  stop();
  iterations = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    chart.clear();
  }
  return d3.select("#message}").text("");
};