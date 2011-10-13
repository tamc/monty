slider = (@opts = {}) ->
  for own key, value of slider.defaults
    @opts[key] = value unless @opts[key]?
  
  # Urgh. Sometimes I don't get Javascript
  that = this
  
  # Set up scales
  x = d3.scale.linear().domain([@opts.x_min,@opts.x_max]).range([0, @opts.width])
  
  # Set up bucket size and corresponding block dimenions  
  # Start the drawing by setting up the surround
  tag = d3.select(@opts.tag)
  tag.append("h2").text(@opts.title) if @opts.title?
  
  # Add a transformation box so we leave space around the edges for axis
  svg = tag.append("svg:svg")
      .attr("width", @opts.width + @opts.padding * 2)
      .attr("height", @opts.height + @opts.padding * 2)
    .append("svg:g")
      .attr("class","main")
      .attr("transform", "translate(" + @opts.padding + "," + @opts.padding + ")")
  
  # This captures clicks
  click_rect = svg.append("svg:rect")
    .attr("class","click")
    .attr("x", 0 )
    .attr("y", 0 )
    .attr("width", @opts.width )
    .attr("height", @opts.height)
  
  # x-axis groups
  xrule = svg.selectAll("g.x")
      .data(x.ticks(@opts.x_ticks))
    .enter().append("svg:g")
      .attr("class", "x");

  # vertical lines on chart
  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", @opts.height);
  
  # x-axis labels
  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", @opts.height + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text( (d) -> x.tickFormat(that.opts.x_ticks)(d)+that.opts.x_axis_suffix );
  
  # x-axis title
  if @opts.x_axis_title?    
    svg.append("svg:text")
      .attr("x",@opts.width/2)
      .attr("y", @opts.height + 18)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(@opts.x_axis_title)

  distribution_move = (d) ->
    # Get the mouse coordinates relative to the origin of the svg group
    m = d3.svg.mouse(svg.node())    
    # Translate those coordinates into mean and probability
    that.opts.mean = x.invert(m[0])
    that.distributionUpdated() if that.distributionUpdated?
    d3.event.preventDefault();

  @allow_distribution_to_be_altered = () ->    
    click_rect.on('click.distribution', distribution_move )

  # Draws a distribution line
  @drawDistributionLine = () ->
    return unless that.opts.mean?  && that.opts.standard_deviation?
    
    svg.append("svg:line")
        .attr('class','distribution')
        .attr("x1", x(that.opts.mean - (3*that.opts.standard_deviation)))
        .attr("x2", x(that.opts.mean - (3*that.opts.standard_deviation)))
        .attr("y1", 0)
        .attr("y2", that.opts.height);

    svg.append("svg:line")
        .attr('class','distribution')
        .attr("x1", x(that.opts.mean + (3*that.opts.standard_deviation)))
        .attr("x2", x(that.opts.mean + (3*that.opts.standard_deviation)))
        .attr("y1", 0)
        .attr("y2", that.opts.height);
    
  @showMedianForDatum = (d) ->
    @showMedianForValue(that.opts.property(d))
  
  @showMedianForValue = (median) ->
    mean = svg.selectAll('line.median')
            .data([1])

    mean.enter().append('svg:line')
      .attr('class','median')

    mean.transition().duration(500)
      .attr('x1', x(median))
      .attr('x2', x(median))
      .attr('y1', 0)
      .attr('y2', that.opts.height)

  @distribution = () ->
    if @opts.mean?
      {distribution: 'fixed', value: @opts.mean}
    else
      {}
  
  this