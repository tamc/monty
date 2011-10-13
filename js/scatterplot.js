var scatterplot;
var __hasProp = Object.prototype.hasOwnProperty;
scatterplot = function(opts) {
  var block_height, block_width, click_rect, count, empty, iteration_to_id, key, point_group, rect, selecting, selection_label, selection_mousedown, selection_mousemove, selection_mouseup, svg, tag, that, value, x, x0, x1, xrule, y, yrule, _ref;
  this.opts = opts != null ? opts : {};
  _ref = scatterplot.defaults;
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
  empty = true;
  this.showMedianForDatum = function(d) {
    var x_median, y_median;
    x_median = svg.selectAll('line.xmedian').data([1]);
    x_median.enter().append('svg:line').attr('class', 'xmedian');
    x_median.transition().duration(500).attr('x1', x(that.opts.x_property(d))).attr('x2', x(that.opts.x_property(d))).attr('y1', 0).attr('y2', that.opts.height);
    y_median = svg.selectAll('line.ymedian').data([1]);
    y_median.enter().append('svg:line').attr('class', 'ymedian');
    return y_median.transition().duration(500).attr('x1', 0).attr('x2', that.opts.width).attr('y1', y(that.opts.y_property(d))).attr('y2', y(that.opts.y_property(d)));
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
    var data_max_x, data_max_y, data_min_x, data_min_y, filter, maxx, maxy, minx, miny;
    if (!selecting) {
      return;
    }
    x1 = d3.svg.mouse(this);
    minx = Math.min(x0[0], x1[0]);
    maxx = Math.max(x0[0], x1[0]);
    miny = Math.min(x0[1], x1[1]);
    maxy = Math.max(x0[1], x1[1]);
    rect.attr("x", minx - .5).attr("y", miny - .5).attr("width", maxx - minx + 1).attr("height", maxy - miny + 1);
    selection_label.attr("x", (minx + maxx) / 2).attr("y", (miny + maxy) / 2).attr("width", maxx - minx + 1).attr("height", maxy - miny + 1);
    data_min_x = x.invert(minx);
    data_max_x = x.invert(maxx);
    data_min_y = y.invert(maxy);
    data_max_y = y.invert(miny);
    count = 0;
    filter = function(d, i) {
      var point_x, point_y;
      point_x = that.opts.x_property(d);
      point_y = that.opts.y_property(d);
      if (point_x >= data_min_x && point_x <= data_max_x && point_y >= data_min_y && point_y <= data_max_y) {
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
  iteration_to_id = function(d) {
    return d.id;
  };
  block_width = 5;
  block_height = 5;
  this.clear = function() {
    d3.selectAll(".selection").remove();
    point_group.selectAll("rect.block").remove();
    return empty = true;
  };
  this.update = function(data) {
    var frequencies;
    this.data = data;
    empty = false;
    frequencies = point_group.selectAll("rect.block").data(data, iteration_to_id);
    frequencies.enter().append("svg:rect").attr("class", function(d) {
      return "block block" + d.id;
    }).attr("x", function(d) {
      return x(that.opts.x_property(d));
    }).attr("y", function(d) {
      return y(that.opts.y_property(d)) - block_height;
    }).attr("width", block_width).attr("height", block_height).style("fill", "yellow").transition().duration(1000).style("fill", "grey");
    return frequencies.exit().remove();
  };
  return this;
};