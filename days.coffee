{round} = Math

# Constants
fontHeight = 14
fontWidth = fontHeight * .75
fontFamily = 'Roboto Mono'

regular = fontHeight + 'px ' + fontFamily
bold = 'bold ' + fontHeight + 'px ' + fontFamily

timer = performance.now()

graph = {}

# fit fits a value between 0 and 1 proportionally to its distance to min and max
fit = (val, min, max) ->
  (val-min)/(max-min)

class Graph
  constructor: (containerName) ->
    req = new XMLHttpRequest()
    req.open('GET', 'https://gadfly16.github.io/sagacity/frames.json')
    req.responseType = 'json'

    @container = document.getElementById(containerName)
    @start_elm = @container.querySelector('#settings>#start')
    @duration_elm = @container.querySelector('#settings>#duration')
    @period_elm = @container.querySelector('#settings>#period')
    @goal_elm = @container.querySelector('#settings>#start')
    @canvas = @container.querySelector('.canvas')
    @setCanvasSize()
    graph = this

    req.onload = ->
      graph.frameList = req.response
      graph.changeSettings()

      graph.container.querySelectorAll('input').forEach(
        (item) -> item.addEventListener('change', graph.changeSettings)
      )

      if graph.canvas.getContext
        # window.onmousedown = mouseDownAct
        # window.onmouseup = mouseUpAct
        window.onmousemove = mouseMoveAct
        window.onresize = resizeAct
        # window.onwheel = wheelAct
        redrawScreen()

    req.send()

  setCanvasSize: () ->
    width = @container.getBoundingClientRect().width
    @canvas.width = width
    @canvas.height = width / 2

  changeSettings: () ->
    @start = (Math.floor((new Date(@start_elm.value)).getTime()/1000) - @frameList[0].ft) / 86400 + 1
    @duration = parseInt(@duration_elm.value)
    @period = parseInt(@period_elm.value)
    @goal = parseFloat(@goal_elm.value)
    # console.log(@start,@duration,@period,@goal)

    # Find trade chances
    i = 0
    end = @frameList.length - @period
    while i < end
      @frameList[i].reBuy = null
      @frameList[i].reSell = null
      reBuyPrice = @frameList[i].mn / @goal
      reSellPrice = @frameList[i].mx * @goal
      fi = i + 1
      while fi <= i + @period && !(@frameList[i].reBuy || @frameList[i].reSell)
        # console.log(i,fi)
        if @frameList[fi].mx < reBuyPrice && !@frameList[i].reBuy
          @frameList[i].reBuy = fi
        if @frameList[fi].mn > reSellPrice && !@frameList[i].reSell
          @frameList[i].reSell = fi
        fi++
      i++

  draw: () ->
    ctx = @canvas.getContext('2d')

    ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    ctx.save()

    cnvRect = @canvas.getBoundingClientRect()

    # Find min and max of displayed frames
    max = @frameList[@start].mx
    min = @frameList[@start].mn
    i = @start + 1
    while i <= @start + @duration
      max = Math.max(max, @frameList[i].mx) 
      min = Math.min(min, @frameList[i].mn)
      i++
    
    # Draw bars
    ctx.fillStyle = '#ff0000'
    barWidth = cnvRect.width / @duration

    offset = @start
    i = 0
    while i <= @duration
      x = i * barWidth
      y = (1-fit(@frameList[offset+i].mx, min, max))*cnvRect.height
      barHeight = (1-fit(@frameList[offset+i].mn, min, max))*cnvRect.height - y
      ctx.fillRect(x, y, barWidth, barHeight)
      i++

    # FPS
    t = performance.now()
    ctx.font = regular
    ctx.textAlign = 'left'
    ctx.fillText(round(1000 / (t - timer)) + " FPS", 50, 50)
    timer = t

    ctx.restore()

resizeAct = ->
  graph.setCanvasSize()
  redrawScreen()

wheelAct = (e) ->
  if e.shiftKey
    vp.rot += e.deltaY / 180 / vp.scale ** .5
  else
    delta = e.deltaY * -0.01
    scale = vp.scale * (1 + delta)
    scale = max(.001, Math.min(1000, scale))
    vp.offx += (vp.width / 2 - e.clientX) * delta * vp.sep ** 2 / vp.unit
    vp.offy += (vp.height / 2 - e.clientY) * delta * vp.sep ** 2 / vp.unit
    vp.scale = scale
    vp.update()
  redrawScreen()

mouseDownAct = (e) ->
  console.log("Pressed$ " + e.clientX)
  vp.panx = e.clientX
  vp.pany = e.clientY
  vp.panstx = vp.offx
  vp.pansty = vp.offy
  vp.panning = true

mouseMoveAct = (e) ->
  # if vp.panning
  #   vp.offx = vp.panstx + (e.clientX - vp.panx) / vp.unit
  #   vp.offy = vp.pansty + (e.clientY - vp.pany) / vp.unit
  #   vp.update()
  # vp.pX = e.clientX
  # vp.pY = e.clientY
  redrawScreen()

mouseUpAct = (e) ->
  vp.panning = false

redrawScreen = ->
  window.requestAnimationFrame(drawScreen)

drawScreen = ->
  graph.draw()

# Entry point. Just like that.

graph = new Graph("doc_graph")
