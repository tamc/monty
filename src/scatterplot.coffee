
scatterplot = (@opts = {}) ->
  # Set default options
  for own key, value of scatterplot.defaults
    @opts[key] = value unless @opts[key]?
  
  # This is our data
  @data = null
  
  that = this
    
  # Set up scales
  x = d3.scale.linear().domain([@opts.x_min,@opts.x_max]).range([0, @opts.width])
  y = d3.scale.linear().domain([@opts.y_min,@opts.y_max]).range([@opts.height, 0])
    
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
  
  xrule = svg.selectAll("g.x")
      .data(x.ticks(@opts.x_ticks))
    .enter().append("svg:g")
      .attr("class", "x");

  xrule.append("svg:line")
      .attr("x1", x)
      .attr("x2", x)
      .attr("y1", 0)
      .attr("y2", @opts.height);

  xrule.append("svg:text")
      .attr("x", x)
      .attr("y", @opts.height + 3)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text( (d) -> x.tickFormat(that.opts.x_ticks)(d)+that.opts.x_axis_suffix );

  if @opts.x_axis_title?    
    svg.append("svg:text")
      .attr("x",@opts.width/2)
      .attr("y", @opts.height + 18)
      .attr("dy", ".71em")
      .attr("text-anchor", "middle")
      .text(@opts.x_axis_title)

  yrule = svg.selectAll("g.y")
      .data(y.ticks(@opts.y_ticks))
    .enter().append("svg:g")
      .attr("class", "y");

  yrule.append("svg:line")
      .attr("x1", 0)
      .attr("x2", @opts.width)
      .attr("y1", y)
      .attr("y2", y);

  yrule.append("svg:text")
      .attr("x", -3)
      .attr("y", y)
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text( (d) -> y.tickFormat(that.opts.y_ticks)(d)+that.opts.y_axis_suffix );
  
  if @opts.y_axis_title?
    svg.append("svg:text")
      .attr("x",-@opts.height/2)
      .attr("y", @opts.width / 2)
      .attr("dy", ".31em")
      .attr("text-anchor", "middle")
      .attr("transform","rotate(-90)translate(0,-#{(@opts.width/2)+30})")
      .text(@opts.y_axis_title)

  point_group = svg.append("svg:g")
  empty = true
  
  @showMedianForDatum = (d) ->
    x_median = svg.selectAll('line.xmedian')
            .data([1])
    
    x_median.enter().append('svg:line')
      .attr('class','xmedian')
    
    x_median.transition().duration(500)
      .attr('x1', x(that.opts.x_property(d)))
      .attr('x2', x(that.opts.x_property(d)))
      .attr('y1', 0)
      .attr('y2', that.opts.height)

    y_median = svg.selectAll('line.ymedian')
            .data([1])
     
    y_median.enter().append('svg:line')
      .attr('class','ymedian')
     
    y_median.transition().duration(500)
      .attr('x1', 0)
      .attr('x2', that.opts.width)
      .attr('y1', y(that.opts.y_property(d)))
      .attr('y2', y(that.opts.y_property(d)))  
  
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

    #x1[0] = Math.max(padding / 2, Math.min(size - padding / 2, x1[0]));
    #x1[1] = Math.max(padding / 2, Math.min(size - padding / 2, x1[1]));

    minx = Math.min(x0[0], x1[0])
    maxx = Math.max(x0[0], x1[0])
    miny = Math.min(x0[1], x1[1])
    maxy = Math.max(x0[1], x1[1])

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
    data_min_y = y.invert(maxy) # Watch out for the scale inversion!
    data_max_y = y.invert(miny)
    
    count = 0
    
    filter = (d,i) ->
      point_x = that.opts.x_property(d)
      point_y = that.opts.y_property(d)
      if point_x >= data_min_x && point_x <= data_max_x && point_y >= data_min_y && point_y <= data_max_y
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
  
  
  iteration_to_id = (d) -> d.id
  block_width = 5
  block_height = 5
  
  @clear = () ->
    d3.selectAll(".selection").remove()
    point_group.selectAll("rect.block").remove()
    empty = true
  
  @update = (data) ->
    @data = data
    empty = false

    frequencies = point_group.selectAll("rect.block")
        .data(data,iteration_to_id)       

    frequencies.enter().append("svg:rect")
        .attr("class",(d) -> "block block#{d.id}")
        .attr("x", (d) -> x(that.opts.x_property(d)) )
        .attr("y", (d) -> y(that.opts.y_property(d))-block_height )
        .attr("width",block_width)
        .attr("height",block_height)
        # .on('mouseover', (d) -> 
        #   d3.selectAll("rect.selected").classed('selected',false)
        #   if stickySelected == true
        #     d3.selectAll(".block#{d.id}").classed('stickySelected',true)
        #   else
        #     d3.selectAll(".block#{d.id}").classed('selected',true)
        # )
        # .on('mouseout', (d) -> d3.selectAll(".block#{d.id}").classed('selected',false))
        .style("fill", "yellow")
        .transition()
          .duration(1000)
          .style("fill", "grey");
        
    frequencies.exit().remove()

  this
