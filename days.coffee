{round, floor} = Math

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
    @goal_elm = @container.querySelector('#settings>#goal')
    @canvas = @container.querySelector('.canvas')
    @focus = 0

    @padLeft = 30
    @padRight = 30
    @padTop = 20
    @padBottom = 40
    @setCanvasSize()

    graph = this

    changeSettings = () ->
      graph.start = (Math.floor((new Date(graph.start_elm.value)).getTime()/1000) - graph.frameList[0].ft) / 86400 + 1
      graph.duration = parseInt(graph.duration_elm.value)
      graph.period = parseInt(graph.period_elm.value)
      graph.goal = parseFloat(graph.goal_elm.value)
      console.log(graph.start,graph.duration,graph.period,graph.goal)

      # Find trade chances
      i = 0
      end = graph.frameList.length - graph.period
      while i < end
        graph.frameList[i].reBuy = null
        graph.frameList[i].reSell = null
        reBuyPrice = graph.frameList[i].mn / graph.goal
        reSellPrice = graph.frameList[i].mx * graph.goal
        fi = i + 1
        while fi <= i + graph.period && !(graph.frameList[i].reBuy && graph.frameList[i].reSell)
          # console.log(i,fi)
          if graph.frameList[fi].mx < reBuyPrice && !graph.frameList[i].reBuy
            graph.frameList[i].reBuy = fi
          if graph.frameList[fi].mn > reSellPrice && !graph.frameList[i].reSell
            graph.frameList[i].reSell = fi
          fi++
        i++
      redrawScreen()

    mouseMoveAct = (e) ->
      x = e.offsetX
      y = e.offsetY
      if x > graph.padLeft && x < graph.padLeft + graph.width && y > graph.padTop && y < graph.padTop + graph.height
        graph.focus = floor((x - graph.padLeft) / (graph.width / graph.duration))
      redrawScreen()

    req.onload = ->
      graph.container.querySelectorAll('input').forEach(
        (item) -> item.addEventListener('change', changeSettings)
      )
      # window.onmousedown = mouseDownAct
      # window.onmouseup = mouseUpAct
      graph.canvas.onmousemove = mouseMoveAct
      window.onresize = resizeAct
      # window.onwheel = wheelAct

      graph.frameList = req.response
      changeSettings()
      console.log(graph.frameList)

    req.send()

  setCanvasSize: () ->
    width = @container.getBoundingClientRect().width
    @canvas.width = width
    @canvas.height = width / 2
    @width = @canvas.width - @padLeft - @padRight
    @height = @canvas.height - @padTop - @padBottom

  changeSettings: () ->
    @start = (Math.floor((new Date(@start_elm.value)).getTime()/1000) - @frameList[0].ft) / 86400 + 1
    @duration = parseInt(@duration_elm.value)
    @period = parseInt(@period_elm.value)
    @goal = parseFloat(@goal_elm.value)

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
    redrawScreen()

  draw: () ->
    ctx = @canvas.getContext('2d')

    ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    ctx.save()
    ctx.lineWidth = 2 ;

    # Find min and max of displayed frames
    max = @frameList[@start].mx
    min = @frameList[@start].mn
    i = @start + 1
    while i <= @start + @duration
      max = Math.max(max, @frameList[i].mx) 
      min = Math.min(min, @frameList[i].mn)
      i++
    
    f = @start + @focus

    # Draw bars
    barWidth = @width / @duration

    gap = 0.1
    offset = @start
    i = 0
    while i <= @duration
      x = i * barWidth + @padLeft
      y = fit(@frameList[offset+i].mx, max, min) * @height
      barHeight = fit(@frameList[offset+i].mn, max, min) * @height - y
      if offset+i == f
        # Draw focus line
        ctx.fillStyle = '#909090'
        ctx.fillRect(x, 0, barWidth, @canvas.height)
        # Store focus values for later use
        fx = x + barWidth / 2
        fy = y + @padTop
        fh = barHeight
      ctx.fillStyle = '#404040'
      if @frameList[offset+i].reSell
        ctx.fillStyle = '#20b020'
      ctx.fillRect(x+barWidth*gap/2, y+@padTop, barWidth*(1-gap), barHeight/2)
      ctx.fillStyle = '#404040'
      if @frameList[offset+i].reBuy
        ctx.fillStyle = '#b04020'
      ctx.fillRect(x+barWidth*gap/2, y+@padTop+barHeight/2, barWidth*(1-gap), barHeight/2)
      i++

    # Draw focus info
    ctx.fillStyle = '#404040'
    ctx.font = bold
    ctx.textAlign = 'center'
    # console.log(@start+@focus)
    fdt = (new Date(@frameList[f].ft*1000)).toDateString()
    fmax = String(@frameList[f].mx)
    fmaxWidth = fontWidth * (fmax.length)
    fmin = String(@frameList[f].mn)
    fminWidth = fontWidth * (fmin.length)
    ctx.fillRect(fx - fmaxWidth / 2, fy - fontHeight - 20, fmaxWidth, fontHeight + 8)
    ctx.fillRect(fx - fminWidth / 2, fy + fh + 12, fminWidth, fontHeight + 8)
    ctx.fillStyle = '#a0a0a0'
    ctx.fillText(fmax, fx, fy - 17)
    ctx.fillText(fmin, fx, fy + fh + 15 + fontHeight)
    ctx.fillStyle = '#404040'
    ctx.fillText(fdt, @canvas.width / 2, @canvas.height - 15)

    rs = @frameList[f].reSell
    if rs
      ctx.strokeStyle = '#20f020'
      ctx.beginPath()
      ctx.moveTo(fx, fy)
      ctx.lineTo(fx+(rs-f)*barWidth, fit(@frameList[rs].mn, max, min) * @height + @padTop)
      ctx.stroke()

      ctx.fillStyle = '#20b020'
      ctx.textAlign = 'right'
      rst = "Re-sell in " + (rs - f) + " days at "
      rsp = @frameList[rs].mn
      ctx.fillText(rst + rsp + " ", @canvas.width / 2, 20)

    rb = @frameList[f].reBuy
    if rb
      ctx.strokeStyle = '#f02020'
      ctx.beginPath()
      ctx.moveTo(fx, fy+fh)
      ctx.lineTo(fx+(rb-f)*barWidth, fit(@frameList[rb].mx, max, min) * @height + @padTop)
      ctx.stroke()

      ctx.fillStyle = '#b02020'
      ctx.textAlign = 'left'
      rbt = " Re-buy in " + (rb - f) + " days at "
      rbp = @frameList[rb].mx
      ctx.fillText(rbt + rbp, @canvas.width / 2, 20)

    # FPS
    t = performance.now()
    ctx.font = regular
    ctx.textAlign = 'left'
    ctx.fillText(round(1000 / (t - timer)) + " FPS", 30, 30)
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

mouseUpAct = (e) ->
  vp.panning = false

redrawScreen = ->
  window.requestAnimationFrame(drawScreen)

drawScreen = ->
  graph.draw()

# Entry point. Just like that.

graph = new Graph("doc_graph")
