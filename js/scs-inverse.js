var charts, defaults, distributionUpdated, distributions, iteration, medians, running, setToDefaults, setup, worker;
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
  "price": {
    distribution: 'normal',
    "mean": 71,
    "sd": (71 - 41) / 3
  },
  "energy_delivered": {
    distribution: 'fixed',
    "value": 20
  },
  "total_profit": {
    distribution: 'fixed',
    "value": 0
  }
};
charts = {};
iteration = [];
running = false;
worker = null;
setup = function() {
  charts = {};
  charts['subsidy'] = new slider({
    tag: '#subsidy',
    x_axis_title: "Level of subsidy (£/MWh)",
    x_max: 200,
    property: function(d) {
      return d.subsidy;
    }
  });
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
    property: function(d) {
      return d.energy_delivered;
    }
  });
  charts['public_spend'] = new slider({
    tag: "#publicSpend",
    x_axis_title: "Public expenditure £bn",
    x_max: 7,
    width: 500,
    property: function(d) {
      return d.public_spend;
    }
  });
  charts['total_profit'] = new slider({
    tag: "#totalProfit",
    x_axis_title: "Private 'excess' profit £bn",
    x_max: 7,
    width: 500,
    property: function(d) {
      return d.total_profit;
    }
  });
  setToDefaults();
  slider.prototype.distributionUpdated = distributionUpdated;
  return d3.select("#calculate").on('click', function() {
    distributionUpdated();
    return false;
  });
};
distributionUpdated = function() {
  stop();
  worker = new Worker('../js/inverse-calculation.js');
  worker.onmessage = function(event) {
    var chart, name, _results;
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
    _results.push(chart != null ? (values.distribution === "normal" ? (chart.opts.mean = values.mean, chart.showMedianForValue(chart.opts.mean)) : values.distribution === "fixed" ? (chart.opts.mean = values.value, chart.showMedianForValue(chart.opts.mean)) : void 0, chart.drawDistributionLine(), chart.allow_distribution_to_be_altered()) : void 0);
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
  return parameters;
};