histogram = (@opts = {}) ->
  # Set default options
  for own key, value of histogram.defaults
    @opts[key] = value unless @opts[key]?
    
  @data = null
    
  # Urgh. Sometimes I don't get Javascript
  that = this
  
  # Set up scales
  x = d3.scale.linear().domain([@opts.x_min,@opts.x_max]).range([0, @opts.width])
  y = d3.scale.linear().domain([@opts.y_min,@opts.y_max]).range([@opts.height, 0])
  
  # Set up bucket size and corresponding block dimenions
  x_step = (x.domain()[1] - x.domain()[0])/@opts.bins
  nesting_operator = d3.nest().key((d) -> Math.round(that.opts.property(d) / x_step) * x_step )
  block_width = x(x_step) - x(0)
  block_height = (@opts.height / @opts.y_max) / (@opts.attempts / 100)
  
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
      .attr('class','axislabel')
      .attr("x",@opts.width/2)
      .attr("y", @opts.height + 18)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(@opts.x_axis_title)
  
  y_axis_group = svg.append("svg:g").attr("class",'yaxisgroup')
  
  # y-axis groups
  yrule = y_axis_group.selectAll("g.y")
      .data(y.ticks(@opts.y_ticks))
    .enter().append("svg:g")
      .attr("class", "y");
  
  # horizontal lines
  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", @opts.width)
      .attr("y1", y)
      .attr("y2", y);
  
  # y-axis labels
  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text( (d) -> y.tickFormat(that.opts.y_ticks)(d)+that.opts.y_axis_suffix );
  
  # optional y-axis titles
  if @opts.y_axis_title?
    y_axis_group.append("svg:text")
      .attr("x",-@opts.height/2)
      .attr("y", @opts.width / 2)
      .attr("dy", ".31em")
      .attr("text-anchor", "middle")
      .attr("transform","rotate(-90)translate(0,-#{(@opts.width/2)+30})")
      .text(@opts.y_axis_title)
    
  # Group to hold all the points
  point_group = svg.append("svg:g")
  empty = true
  
  distribution_move = (d) ->
    return unless empty == true
    # Get the mouse coordinates relative to the origin of the svg group
    m = d3.svg.mouse(svg.node())    
    # Translate those coordinates into mean and probability
    that.opts.mean = x.invert(m[0])
    if that.opts.standard_deviation
      that.opts.standard_deviation = inverse_probability_in_mean_bin(y.invert(m[1])/100,that.opts.mean, x_step) 
    that.drawDistributionLine()
    that.distributionUpdated() if that.distributionUpdated?
    d3.event.preventDefault();
  
  @allow_distribution_to_be_altered = () ->    
    click_rect.on('click.distribution', distribution_move )
    
  # Draws a distribution line
  @drawDistributionLine = () ->    
    return unless that.opts.mean?  && that.opts.standard_deviation?

    # Point to line mapping
    line = d3.svg.line().x((d) -> x(d.x)).y((d) -> y(d.y))
    
    # Calculate the points
    points = x.ticks(100).map( (d) -> {x:d, y: probability_in_bin(d,that.opts.mean,that.opts.standard_deviation,x_step)*100 } )
    
    curve = svg.selectAll('path.distribution')
        .data([points])
            
    curve.enter().append('svg:path')
        .attr('class','distribution toggleWithDistribution')
    
    curve.transition().duration(500).attr('d',line)
    
    that.distributionUpdated() if that.distributionUpdated?
  
  @showMedianForDatum = (d) ->
    mean = svg.selectAll('line.median')
            .data([1])
    
    mean.enter().append('svg:line')
      .attr('class','median')
    
    mean.transition().duration(500)
      .attr('x1', x(that.opts.property(d)))
      .attr('x2', x(that.opts.property(d)))
      .attr('y1', 0)
      .attr('y2', that.opts.height)
  
  @distribution = () ->
    if @opts.mean? && @opts.standard_deviation?
      {distribution: 'normal', mean: @opts.mean, sd:@opts.standard_deviation}
    else if @opts.mean?
      {distribution: 'fixed', value: @opts.mean}
    else
      {}
    
  rect = null
  selection_label = null
  x0 = 0
  x1 = 0
  count = null
  selecting = false

  selection_mousedown = () ->
    return if empty
    return if selecting
    selecting = true
    d3.selectAll(".selection").remove()
    x0 = d3.svg.mouse(this);
    count = 0;
    
    rect = d3.select(this.parentNode).append("svg:rect")
        .attr("class","selection")
        .style("stroke","none")
        .style("fill", "#999")
        .style("fill-opacity", .5)
        .style("pointer-events","none")
    
    selection_label = d3.select(this.parentNode)
        .append("svg:text")
        .attr("class","selection")        
        .style("text-anchor","middle")

    d3.event.preventDefault();
    
  selection_mousemove = () ->
    return unless selecting
    x1 = d3.svg.mouse(this)

    minx = Math.min(x0[0], x1[0])
    maxx = Math.max(x0[0], x1[0])
    miny = 0 # Math.min(x0[1], x1[1])
    maxy = opts.height # Math.max(x0[1], x1[1])

    rect
        .attr("x", minx - .5)
        .attr("y", miny - .5)
        .attr("width", maxx - minx + 1)
        .attr("height", maxy - miny + 1)
        
    selection_label
      .attr("x", (minx  + maxx) / 2)
      .attr("y", (miny + maxy) / 2)
      .attr("width", maxx - minx + 1)
      .attr("height", maxy - miny + 1)
    
    data_min_x = x.invert(minx)
    data_max_x = x.invert(maxx)
    
    count = 0
    
    filter = (d,i) ->
      point = that.opts.property(d)
      if point >= data_min_x && point <= data_max_x
        d3.selectAll(".block#{d.id}").classed("selected",true).style("fill", "yellow")
        count++
    
    d3.selectAll("rect.selected").classed("selected",false).style("fill", "grey")
    
    point_group.selectAll("rect.block").each(filter)
    
    selection_label.text("Selected #{count} out of #{that.data.length} (#{Math.round((count/that.data.length)*100)}%)")
    
  selection_mouseup = () ->
    return unless selecting
    selecting = false
    
    if count == 0
      rect.remove()
      rect = null
      selection_label.remove()
      selection_label = null
      d3.selectAll("rect.selected").classed("selected",false).style("fill", "grey")

  click_rect
    .on('mousedown.selection',selection_mousedown)
    .on('mousemove.selection',selection_mousemove)  
    .on('mouseup.selection',selection_mouseup)    
    .on('mouseout.selection',selection_mouseup)    
  
  values_to_ids = (d) -> d.key
  values_to_frequencies = (d) -> d.values
  iteration_to_id = (d) -> +d.id
  
  # Removes histogram points from the chart
  @clear = () ->    
    d3.selectAll(".selection").remove()
    point_group.selectAll("g.value").remove()
    empty = true
  
  # Updates the histogram points on the chart
  @update = (data) ->
    empty = false
    @data = data
    
    # Turn the data into buckets    
    buckets = nesting_operator.entries(data)
    
    # Add a group for each bucket
    values = point_group.selectAll("g.value")
      .data(buckets,values_to_ids)
      
    values.enter().append("svg:g")
      .attr("class", "value")
      .attr("transform", (d) -> "translate(#{x(+d.key-(x_step/2))},0)")

    values.exit().remove()
    
    # Add a rectangle for each element in each bucket
    frequencies = values.selectAll("rect")
        .data(values_to_frequencies,iteration_to_id)       
        
    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block block#{d.id}")
        .attr("y", (d,i) -> that.opts.height - ((i+1)*block_height) )
        .attr("width",block_width)
        .attr("height",block_height)
        .style("fill", "yellow")
        .transition()
          .duration(1000)
          .style("fill", "grey");
    
    frequencies.exit().remove()
  
  distribution_displayed = true
  point_group.classed('toggleWithDistribution',true)
  svg.selectAll('.yaxisgroup').classed('toggleWithDistribution',true)
    
  @toggleDistributions = () ->
    if distribution_displayed == true
      svg.selectAll('.toggleWithDistribution').attr("style","visibility:hidden")
      distribution_displayed = false
    else
      svg.selectAll('.toggleWithDistribution').attr("style","visibility:visible")
      distribution_displayed = true
  
  this
