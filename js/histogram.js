var histogram;
var __hasProp = Object.prototype.hasOwnProperty;
histogram = function(opts) {
  var block_height, block_width, click_rect, count, distribution_displayed, distribution_move, empty, iteration_to_id, key, nesting_operator, point_group, rect, selecting, selection_label, selection_mousedown, selection_mousemove, selection_mouseup, svg, tag, that, value, values_to_frequencies, values_to_ids, x, x0, x1, x_step, xrule, y, y_axis_group, yrule, _ref;
  this.opts = opts != null ? opts : {};
  _ref = histogram.defaults;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    if (this.opts[key] == null) {
      this.opts[key] = value;
    }
  }
  this.data = null;
  that = this;
  x = d3.scale.linear().domain([this.opts.x_min, this.opts.x_max]).range([0, this.opts.width]);
  y = d3.scale.linear().domain([this.opts.y_min, this.opts.y_max]).range([this.opts.height, 0]);
  x_step = (x.domain()[1] - x.domain()[0]) / this.opts.bins;
  nesting_operator = d3.nest().key(function(d) {
    return Math.round(that.opts.property(d) / x_step) * x_step;
  });
  block_width = x(x_step) - x(0);
  block_height = (this.opts.height / this.opts.y_max) / (this.opts.attempts / 100);
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
  y_axis_group = svg.append("svg:g").attr("class", 'yaxisgroup');
  yrule = y_axis_group.selectAll("g.y").data(y.ticks(this.opts.y_ticks)).enter().append("svg:g").attr("class", "y");
  yrule.append("svg:line").attr("x1", 0).attr("x2", this.opts.width).attr("y1", y).attr("y2", y);
  yrule.append("svg:text").attr("x", -3).attr("y", y).attr("dy", ".35em").attr("text-anchor", "end").text(function(d) {
    return y.tickFormat(that.opts.y_ticks)(d) + that.opts.y_axis_suffix;
  });
  if (this.opts.y_axis_title != null) {
    y_axis_group.append("svg:text").attr("x", -this.opts.height / 2).attr("y", this.opts.width / 2).attr("dy", ".31em").attr("text-anchor", "middle").attr("transform", "rotate(-90)translate(0,-" + ((this.opts.width / 2) + 30) + ")").text(this.opts.y_axis_title);
  }
  point_group = svg.append("svg:g");
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
    if (that.distributionUpdated != null) {
      that.distributionUpdated();
    }
    return d3.event.preventDefault();
  };
  this.allow_distribution_to_be_altered = function() {
    return click_rect.on('click.distribution', distribution_move);
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
    curve.enter().append('svg:path').attr('class', 'distribution toggleWithDistribution');
    curve.transition().duration(500).attr('d', line);
    if (that.distributionUpdated != null) {
      return that.distributionUpdated();
    }
  };
  this.showMedianForDatum = function(d) {
    var mean;
    mean = svg.selectAll('line.median').data([1]);
    mean.enter().append('svg:line').attr('class', 'median');
    return mean.transition().duration(500).attr('x1', x(that.opts.property(d))).attr('x2', x(that.opts.property(d))).attr('y1', 0).attr('y2', that.opts.height);
  };
  this.distribution = function() {
    if ((this.opts.mean != null) && (this.opts.standard_deviation != null)) {
      return {
        distribution: 'normal',
        mean: this.opts.mean,
        sd: this.opts.standard_deviation
      };
    } else {
      return {};
    }
  };
  rect = null;
  selection_label = null;
  x0 = 0;
  x1 = 0;
  count = null;
  selecting = false;
  selection_mousedown = function() {
    if (empty) {
      return;
    }
    if (selecting) {
      return;
    }
    selecting = true;
    d3.selectAll(".selection").remove();
    x0 = d3.svg.mouse(this);
    count = 0;
    rect = d3.select(this.parentNode).append("svg:rect").attr("class", "selection").style("stroke", "none").style("fill", "#999").style("fill-opacity", .5).style("pointer-events", "none");
    selection_label = d3.select(this.parentNode).append("svg:text").attr("class", "selection").style("text-anchor", "middle");
    return d3.event.preventDefault();
  };
  selection_mousemove = function() {
    var data_max_x, data_min_x, filter, maxx, maxy, minx, miny;
    if (!selecting) {
      return;
    }
    x1 = d3.svg.mouse(this);
    minx = Math.min(x0[0], x1[0]);
    maxx = Math.max(x0[0], x1[0]);
    miny = 0;
    maxy = opts.height;
    rect.attr("x", minx - .5).attr("y", miny - .5).attr("width", maxx - minx + 1).attr("height", maxy - miny + 1);
    selection_label.attr("x", (minx + maxx) / 2).attr("y", (miny + maxy) / 2).attr("width", maxx - minx + 1).attr("height", maxy - miny + 1);
    data_min_x = x.invert(minx);
    data_max_x = x.invert(maxx);
    count = 0;
    filter = function(d, i) {
      var point;
      point = that.opts.property(d);
      if (point >= data_min_x && point <= data_max_x) {
        d3.selectAll(".block" + d.id).classed("selected", true).style("fill", "yellow");
        return count++;
      }
    };
    d3.selectAll("rect.selected").classed("selected", false).style("fill", "grey");
    point_group.selectAll("rect.block").each(filter);
    return selection_label.text("Selected " + count + " out of " + that.data.length + " (" + (Math.round((count / that.data.length) * 100)) + "%)");
  };
  selection_mouseup = function() {
    if (!selecting) {
      return;
    }
    selecting = false;
    if (count === 0) {
      rect.remove();
      rect = null;
      selection_label.remove();
      selection_label = null;
      return d3.selectAll("rect.selected").classed("selected", false).style("fill", "grey");
    }
  };
  click_rect.on('mousedown.selection', selection_mousedown).on('mousemove.selection', selection_mousemove).on('mouseup.selection', selection_mouseup).on('mouseout.selection', selection_mouseup);
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
    d3.selectAll(".selection").remove();
    point_group.selectAll("g.value").remove();
    return empty = true;
  };
  this.update = function(data) {
    var buckets, frequencies, values;
    empty = false;
    this.data = data;
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
    }).attr("width", block_width).attr("height", block_height).style("fill", "yellow").transition().duration(1000).style("fill", "grey");
    return frequencies.exit().remove();
  };
  distribution_displayed = true;
  point_group.classed('toggleWithDistribution', true);
  svg.selectAll('.yaxisgroup').classed('toggleWithDistribution', true);
  this.toggleDistributions = function() {
    if (distribution_displayed === true) {
      svg.selectAll('.toggleWithDistribution').attr("style", "visibility:hidden");
      return distribution_displayed = false;
    } else {
      svg.selectAll('.toggleWithDistribution').attr("style", "visibility:visible");
      return distribution_displayed = true;
    }
  };
  return this;
};