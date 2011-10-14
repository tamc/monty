var slider;
var __hasProp = Object.prototype.hasOwnProperty;
slider = function(opts) {
  var click_rect, distribution_move, key, svg, tag, that, value, x, xrule, _ref;
  this.opts = opts != null ? opts : {};
  _ref = slider.defaults;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    if (this.opts[key] == null) {
      this.opts[key] = value;
    }
  }
  that = this;
  x = d3.scale.linear().domain([this.opts.x_min, this.opts.x_max]).range([0, this.opts.width]);
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
    svg.append("svg:text").attr('class', 'axislabel').attr("x", this.opts.width / 2).attr("y", this.opts.height + 18).attr("dy", ".71em").attr("text-anchor", "middle").text(this.opts.x_axis_title);
  }
  distribution_move = function(d) {
    var m;
    m = d3.svg.mouse(svg.node());
    that.opts.mean = x.invert(m[0]);
    if (that.distributionUpdated != null) {
      that.distributionUpdated();
    }
    return d3.event.preventDefault();
  };
  this.allow_distribution_to_be_altered = function() {
    return click_rect.on('click.distribution', distribution_move);
  };
  this.drawDistributionLine = function() {
    if (!((that.opts.mean != null) && (that.opts.standard_deviation != null))) {
      return;
    }
    return svg.append("svg:rect").attr('class', 'distribution').attr("x", x(that.opts.mean - (3 * that.opts.standard_deviation))).attr("y", 0).attr("width", x(that.opts.mean + (3 * that.opts.standard_deviation)) - x(that.opts.mean - (3 * that.opts.standard_deviation))).attr("height", that.opts.height);
  };
  this.showMedianForDatum = function(d) {
    return this.showMedianForValue(that.opts.property(d));
  };
  this.showMedianForValue = function(median) {
    var mean;
    mean = svg.selectAll('line.median').data([1]);
    mean.enter().append('svg:line').attr('class', 'median');
    return mean.transition().duration(500).attr('x1', x(median)).attr('x2', x(median)).attr('y1', 0).attr('y2', that.opts.height);
  };
  this.distribution = function() {
    if (this.opts.mean != null) {
      return {
        distribution: 'fixed',
        value: this.opts.mean
      };
    } else {
      return {};
    }
  };
  return this;
};