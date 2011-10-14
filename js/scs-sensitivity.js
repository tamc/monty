var best, central, charts, iteration, running, setup, worker, worst;
var __hasProp = Object.prototype.hasOwnProperty;
charts = {};
iteration = [];
running = false;
worker = null;
setup = function() {
  charts = setupCharts(slider);
  setToDefaults();
  slider.prototype.distributionUpdated = distributionUpdated;
  distributionUpdated();
  d3.select("#worst").on('click', function() {
    worst();
    return false;
  });
  d3.select("#central").on('click', function() {
    central();
    return false;
  });
  return d3.select("#best").on('click', function() {
    best();
    return false;
  });
};
central = function() {
  var chart, data, name, _results;
  data = {
    "id": 'central',
    "subsidy": 94,
    "capital_cost": 2211,
    "operating_cost": 132,
    "fuel_cost": 0,
    "efficiency": 100,
    "availability": 30,
    "economic_life": 25,
    "hurdle_rate": 13,
    "capital_available": 17,
    "price": 71,
    "capital_falloff": 4.25,
    "capital_rampup": 0.25,
    "annualCapitalCost": 301.63772592929513,
    "annualOutput": 2.6298,
    "annualCost": 433.63772592929513,
    "cost_per_MWh": 164.89380406467987,
    "annualIncome": 433.917,
    "profit": 0.2792740707048438,
    "internal_rate_of_return": 13.01402929349971,
    "actual_capital_available": 17.003507323374926,
    "deployment": 7690.414890716836,
    "energy_delivered": 20.224253079607138,
    "public_spend": 1.9010797894830709,
    "total_profit": 0.0021477334719396373
  };
  _results = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    _results.push(chart.showMedianForDatum(data));
  }
  return _results;
};
worst = function() {
  var chart, data, name, _results;
  data = {
    "id": 'worst',
    "subsidy": 94,
    "capital_cost": 3621.4285714285716,
    "operating_cost": 210,
    "fuel_cost": 0,
    "efficiency": 100,
    "availability": 17.71428571428571,
    "economic_life": 12.857142857142856,
    "hurdle_rate": 19.02857142857143,
    "capital_available": 11,
    "price": 41.142857142857146,
    "capital_falloff": 7.285714285714286,
    "capital_rampup": 0.02857142857142857,
    "annualCapitalCost": 771.2418331093793,
    "annualOutput": 1.5528342857142856,
    "annualCost": 981.2418331093793,
    "cost_per_MWh": 631.903765995236,
    "annualIncome": 209.85446204081632,
    "profit": -771.387371068563,
    "internal_rate_of_return": null,
    "actual_capital_available": null,
    "deployment": null,
    "energy_delivered": null,
    "public_spend": null,
    "total_profit": null
  };
  _results = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    _results.push(chart.showMedianForDatum(data));
  }
  return _results;
};
best = function() {
  var chart, data, name, _results;
  data = {
    "id": 'best',
    "subsidy": 94,
    "capital_cost": 814.2857142857142,
    "operating_cost": 55.714285714285715,
    "fuel_cost": 0,
    "efficiency": 100,
    "availability": 42,
    "economic_life": 37.142857142857146,
    "hurdle_rate": 6.914285714285714,
    "capital_available": 23,
    "price": 101.14285714285714,
    "capital_falloff": 1.2571428571428571,
    "capital_rampup": 3.257142857142857,
    "annualCapitalCost": 61.42955757756015,
    "annualOutput": 3.68172,
    "annualCost": 117.14384329184587,
    "cost_per_MWh": 31.817694798041643,
    "annualIncome": 718.46136,
    "profit": 601.3175167081541,
    "internal_rate_of_return": 81.38999144898641,
    "actual_capital_available": 265.5780129644537,
    "deployment": 326148.4369738905,
    "energy_delivered": 1200.7872233755122,
    "public_spend": 112.87399899729814,
    "total_profit": 196.11876819938576
  };
  _results = [];
  for (name in charts) {
    if (!__hasProp.call(charts, name)) continue;
    chart = charts[name];
    _results.push(chart.showMedianForDatum(data));
  }
  return _results;
};