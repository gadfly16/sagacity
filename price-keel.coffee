{round, floor, log, log10, min, max, abs, ceil} = Math

# Constants
FONTHEIGHT = 14
FONTWIDTH = FONTHEIGHT * .75
FONT_FAMILY = 'Roboto Mono'

REGULAR = FONTHEIGHT + 'px ' + FONT_FAMILY
BOLD = 'BOLD ' + FONTHEIGHT + 'px ' + FONT_FAMILY

GREEN = '#20b020'
RED = '#b02020'
BLUE = '#2020b0'

DARK_GREY = '#404040'
GREY = '#909090'
LIGHT_GREY = '#a0a0a0'

timer = performance.now()

graph = {}

# fit fits a value between 0 and 1 proportionally to its distance to minimum and maximum
fit = (val, minimum, maximum) ->
  (val-minimum)/(maximum-minimum)

fitClamp = (val, minimum, maximum) ->
  max(0,min(1,(val-minimum)/(maximum-minimum)))

class Graph
  constructor: (containerName) ->
    req = new XMLHttpRequest()
    req.open('GET', 'https://gadfly16.github.io/sagacity/frames.json')
    req.responseType = 'json'

    @container = document.getElementById(containerName)
    @start_elm = @container.querySelector('#settings>#start')
    @duration_elm = @container.querySelector('#settings>#duration')
    @top_elm = @container.querySelector('#settings>#top')
    @bottom_elm = @container.querySelector('#settings>#bottom')
    @initial_elm = @container.querySelector('#settings>#initial')
    @threshold_elm = @container.querySelector('#settings>#threshold')
    @canvas = @container.querySelector('.canvas')
    @focus = 0

    @padLeft = 30
    @padRight = 30
    @padTop = 20
    @padBottom = 40
    @setCanvasSize()

    graph = this

    changeSettings = () ->
      graph.start = (floor((new Date(graph.start_elm.value)).getTime()/1000) - graph.frames[0].ft) / 86400
      graph.duration = parseInt(graph.duration_elm.value)
      graph.top = parseFloat(graph.top_elm.value)
      graph.bottom = parseFloat(graph.bottom_elm.value)
      graph.initial = parseFloat(graph.initial_elm.value)
      graph.threshold = parseFloat(graph.threshold_elm.value)
      console.log(graph.start,graph.duration,graph.top,graph.bottom, graph.initial)

      # Simulate trading
      fee = 0.0016
      i = graph.start
      eur = graph.initial
      ada = 0
      ltop = log(graph.top)
      lbottom = log(graph.bottom)
      cumfee = 0
      lastPrice = 0
      maximum = graph.frames[graph.start].mx
      minimum = graph.frames[graph.start].mn
      while i < graph.start + graph.duration
        maximum = max(maximum, graph.frames[i].mx) 
        minimum = min(minimum, graph.frames[i].mn)
        price = graph.frames[i].wa
        if lastPrice == 0 or max(price, lastPrice) / min(price, lastPrice) > 1 + graph.threshold
          lprice = log(price)
          ratio = fitClamp(lprice, lbottom, ltop)
          sumval = price * ada + eur
          tradeval = eur - ratio * sumval
          tradefee = abs(tradeval) * fee
          cumfee += tradefee
          ada += tradeval / price
          eur -= tradeval + tradefee
          graph.frames[i].tv = tradeval
          lastPrice = price
        else
          graph.frames[i].tv = 0
        graph.frames[i].adaval = ada * price
        graph.frames[i].eur = eur

        console.log(price, ratio, tradeval, ada, eur, (new Date(graph.frames[i].ft*1000)).toDateString(), sumval, cumfee)
        i++

      graph.maximum = max(maximum, graph.top)
      graph.minimum = min(minimum, graph.bottom)
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

      graph.frames = req.response
      changeSettings()
      console.log(graph.frames)

    req.send()

  drawHorizLine: (price, color) ->
    y = @priceToY(price)
    @ctx.strokeStyle = color
    @ctx.beginPath()
    @ctx.moveTo(@padLeft, y)
    @ctx.lineTo(@canvas.width-@padRight, y)
    @ctx.stroke()

  setCanvasSize: () ->
    width = @container.getBoundingClientRect().width
    @canvas.width = width
    @canvas.height = width / 2
    @width = @canvas.width - @padLeft - @padRight
    @height = @canvas.height - @padTop - @padBottom

  priceToY: (price) ->
    fit(price, @maximum, @minimum) * @height + @padTop

  draw: () ->
    @ctx = @canvas.getContext('2d')

    @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    @ctx.save()

    f = @start + @focus

    # Draw scale lines
    range = @maximum - @minimum
    scale = 10 ** (floor(log10(range))-1)
    first = ceil(@minimum/scale)*scale
    last = floor(@maximum/scale)*scale

    @ctx.lineWidth = 0.5 ;
    @ctx.fillStyle = LIGHT_GREY
    @ctx.font = REGULAR
    @ctx.textAlign = 'center'
    @ctx.textBaseline = 'middle'
    prec = if scale >= 1 then 0 else abs(log10(scale))

    s = first
    while s <= last
      @drawHorizLine(s, LIGHT_GREY)
      @ctx.fillText(s.toFixed(prec), @padLeft / 2, @priceToY(s))
      s += scale

    @ctx.textBaseline = 'alphabetic'

    # Draw bars
    gap = 0.1
    barWidth = @width / @duration
    offset = @start
    i = 0
    while i <= @duration
      x = i * barWidth + @padLeft
      y = @priceToY(@frames[offset+i].mx)
      barHeight = @priceToY(@frames[offset+i].mn) - y
      if offset+i == f
        # Draw focus line
        @ctx.fillStyle = GREY
        @ctx.fillRect(x, 0, barWidth, @canvas.height)
        # Store focus values for later use
        fx = x + barWidth / 2
        fy = y
        fh = barHeight
      @ctx.fillStyle = DARK_GREY
      if @frames[offset+i].tv > 0
        @ctx.fillStyle = GREEN
      else if @frames[offset+i].tv < 0
        @ctx.fillStyle = RED
      else
        @ctx.fillStyle = DARK_GREY
      @ctx.fillRect(x+barWidth*gap/2, y, barWidth*(1-gap), barHeight)
      @ctx.fillStyle = DARK_GREY
      i++

    fframe = @frames[f]

    # Draw focus info
    @ctx.fillStyle = DARK_GREY
    @ctx.font = BOLD
    @ctx.textAlign = 'center'
    # console.log(@start+@focus)
    fdt = (new Date(fframe.ft*1000)).toDateString()
    ftv = fframe.tv
    ftrade = (if ftv >0 then 'Buy: ' else 'Sell: ') + (abs(ftv)/graph.frames[f].wa).toFixed(4) + ' for ' + abs(ftv).toFixed(2) + ' at ' + abs(fframe.wa).toFixed(2)
    ftradeWidth = FONTWIDTH * (ftrade.length)
    fresult = fframe.adaval.toFixed(2) + '/' + fframe.eur.toFixed(2) + ' (' + (fframe.adaval+fframe.eur).toFixed(3) + ')'
    fresultWidth = FONTWIDTH * (fresult.length)
    @ctx.fillRect(fx - ftradeWidth / 2, fy - FONTHEIGHT - 20, ftradeWidth, FONTHEIGHT + 8)
    @ctx.fillRect(fx - fresultWidth / 2, fy + fh + 12, fresultWidth, FONTHEIGHT + 8)
    @ctx.fillStyle = if ftv > 0 then GREEN else RED
    @ctx.fillText(ftrade, fx, fy - 17)
    @ctx.fillStyle = LIGHT_GREY
    @ctx.fillText(fresult, fx, fy + fh + 15 + FONTHEIGHT)
    @ctx.fillStyle = DARK_GREY
    @ctx.fillText(fdt, @canvas.width / 2, @canvas.height - 15)

    # Draw top and bottom lines
    @ctx.lineWidth = 1 ;
    @drawHorizLine(@bottom, GREEN)
    @drawHorizLine(@top, RED)
    @drawHorizLine(Math.E**((log(@bottom) + log(@top)) / 2), BLUE)

    # Draw summary
    startPrice = parseFloat(@frames[@start].wa)
    startAda = @initial / startPrice
    endPrice = parseFloat(@frames[@start+@duration].wa)
    endValue = @frames[@start+@duration-1].adaval + @frames[@start+@duration-1].eur
    endAda = endValue / endPrice
    endResultEur = endValue / @initial
    endResultAda = endAda / startAda
    # console.log(typeof(startPrice))
    summary = 'Start price: ' + startPrice.toFixed(2) + ' Start ADA: ' + startAda.toFixed(2) + ' End price: ' + endPrice.toFixed(2) + ' (' + (endPrice/startPrice).toFixed(2) + ') End ADA:' + endAda.toFixed(2) + ' Result EUR: ' + endResultEur.toFixed(2)+ ' Result ADA: ' + endResultAda.toFixed(2)
    @ctx.fillStyle = DARK_GREY
    @ctx.fillText(summary, @canvas.width / 2, 25)

    # FPS
    t = performance.now()
    @ctx.font = REGULAR
    @ctx.textAlign = 'left'
    @ctx.fillText(round(1000 / (t - timer)) + " FPS", 30, 30)
    timer = t

    @ctx.restore()

resizeAct = ->
  graph.setCanvasSize()
  redrawScreen()

wheelAct = (e) ->
  if e.shiftKey
    vp.rot += e.deltaY / 180 / vp.scale ** .5
  else
    delta = e.deltaY * -0.01
    scale = vp.scale * (1 + delta)
    scale = max(.001, min(1000, scale))
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
