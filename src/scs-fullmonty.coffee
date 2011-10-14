setNumberOfAttempts = (attempts) ->
  for own name, chart of charts  
    if chart.setBlockHeight?
      chart.setBlockHeight(attempts)
  

setup = () ->
    charts = setupCharts(histogram)
      
    # Set up the controls
    d3.select("#oneRun").on('click',() -> start(1); return false)
    d3.select("#tenRuns").on('click',() -> clear(); setNumberOfAttempts(10); start(10); return false)
    d3.select("#hundredRuns").on('click',() -> clear(); setNumberOfAttempts(100); start(100);return false)
    d3.select("#fiveHundredRuns").on('click',() -> clear(); setNumberOfAttempts(500); start(500); return false)
    d3.select("#stopButton").on('click',() -> stop(); return false)
    d3.select("#clearButton").on('click',() -> clear(); return false)
    d3.select("#defaultsButton").on('click',() -> clear(); setToDefaults(); return false)
    d3.select("#toggleDistributions").on('click',() -> clear(); toggleDistributions(); return false)

    setToDefaults()
    histogram.prototype.distributionUpdated = distributionUpdated    
    distributionUpdated()
    
