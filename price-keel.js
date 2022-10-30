// Generated by CoffeeScript 2.7.0
(function() {
  var BLUE, BOLD, DARK_GREY, FONTHEIGHT, FONTWIDTH, FONT_FAMILY, GREEN, GREY, Graph, LIGHT_GREY, RED, REGULAR, abs, ceil, drawScreen, fit, fitClamp, floor, graph, log, log10, max, min, mouseDownAct, mouseUpAct, redrawScreen, resizeAct, round, timer, wheelAct;

  ({round, floor, log, log10, min, max, abs, ceil} = Math);

  // Constants
  FONTHEIGHT = 14;

  FONTWIDTH = FONTHEIGHT * .75;

  FONT_FAMILY = 'Roboto Mono';

  REGULAR = FONTHEIGHT + 'px ' + FONT_FAMILY;

  BOLD = 'BOLD ' + FONTHEIGHT + 'px ' + FONT_FAMILY;

  GREEN = '#20b020';

  RED = '#b02020';

  BLUE = '#2020b0';

  DARK_GREY = '#404040';

  GREY = '#909090';

  LIGHT_GREY = '#a0a0a0';

  timer = performance.now();

  graph = {};

  // fit fits a value between 0 and 1 proportionally to its distance to minimum and maximum
  fit = function(val, minimum, maximum) {
    return (val - minimum) / (maximum - minimum);
  };

  fitClamp = function(val, minimum, maximum) {
    return max(0, min(1, (val - minimum) / (maximum - minimum)));
  };

  Graph = class Graph {
    constructor(containerName) {
      var changeSettings, mouseMoveAct, req;
      req = new XMLHttpRequest();
      req.open('GET', 'https://gadfly16.github.io/sagacity/frames.json');
      req.responseType = 'json';
      this.container = document.getElementById(containerName);
      this.start_elm = this.container.querySelector('#settings>#start');
      this.duration_elm = this.container.querySelector('#settings>#duration');
      this.top_elm = this.container.querySelector('#settings>#top');
      this.bottom_elm = this.container.querySelector('#settings>#bottom');
      this.initial_elm = this.container.querySelector('#settings>#initial');
      this.threshold_elm = this.container.querySelector('#settings>#threshold');
      this.canvas = this.container.querySelector('.canvas');
      this.focus = 0;
      this.padLeft = 30;
      this.padRight = 30;
      this.padTop = 20;
      this.padBottom = 40;
      this.setCanvasSize();
      graph = this;
      changeSettings = function() {
        var ada, cumfee, eur, fee, i, lastPrice, lbottom, lprice, ltop, maximum, minimum, price, ratio, sumval, tradefee, tradeval;
        graph.start = (floor((new Date(graph.start_elm.value)).getTime() / 1000) - graph.frames[0].ft) / 86400;
        graph.duration = parseInt(graph.duration_elm.value);
        graph.top = parseFloat(graph.top_elm.value);
        graph.bottom = parseFloat(graph.bottom_elm.value);
        graph.initial = parseFloat(graph.initial_elm.value);
        graph.threshold = parseFloat(graph.threshold_elm.value);
        console.log(graph.start, graph.duration, graph.top, graph.bottom, graph.initial);
        // Simulate trading
        fee = 0.0016;
        i = graph.start;
        eur = graph.initial;
        ada = 0;
        ltop = log(graph.top);
        lbottom = log(graph.bottom);
        cumfee = 0;
        lastPrice = 0;
        maximum = graph.frames[graph.start].mx;
        minimum = graph.frames[graph.start].mn;
        while (i < graph.start + graph.duration) {
          maximum = max(maximum, graph.frames[i].mx);
          minimum = min(minimum, graph.frames[i].mn);
          price = graph.frames[i].wa;
          if (lastPrice === 0 || max(price, lastPrice) / min(price, lastPrice) > 1 + graph.threshold) {
            lprice = log(price);
            ratio = fitClamp(lprice, lbottom, ltop);
            sumval = price * ada + eur;
            tradeval = eur - ratio * sumval;
            tradefee = abs(tradeval) * fee;
            cumfee += tradefee;
            ada += tradeval / price;
            eur -= tradeval + tradefee;
            graph.frames[i].tv = tradeval;
            lastPrice = price;
          } else {
            graph.frames[i].tv = 0;
          }
          graph.frames[i].adaval = ada * price;
          graph.frames[i].eur = eur;
          console.log(price, ratio, tradeval, ada, eur, (new Date(graph.frames[i].ft * 1000)).toDateString(), sumval, cumfee);
          i++;
        }
        graph.maximum = max(maximum, graph.top);
        graph.minimum = min(minimum, graph.bottom);
        return redrawScreen();
      };
      mouseMoveAct = function(e) {
        var x, y;
        x = e.offsetX;
        y = e.offsetY;
        if (x > graph.padLeft && x < graph.padLeft + graph.width && y > graph.padTop && y < graph.padTop + graph.height) {
          graph.focus = floor((x - graph.padLeft) / (graph.width / graph.duration));
        }
        return redrawScreen();
      };
      req.onload = function() {
        graph.container.querySelectorAll('input').forEach(function(item) {
          return item.addEventListener('change', changeSettings);
        });
        // window.onmousedown = mouseDownAct
        // window.onmouseup = mouseUpAct
        graph.canvas.onmousemove = mouseMoveAct;
        window.onresize = resizeAct;
        // window.onwheel = wheelAct
        graph.frames = req.response;
        changeSettings();
        return console.log(graph.frames);
      };
      req.send();
    }

    drawHorizLine(price, color) {
      var y;
      y = this.priceToY(price);
      this.ctx.strokeStyle = color;
      this.ctx.beginPath();
      this.ctx.moveTo(this.padLeft, y);
      this.ctx.lineTo(this.canvas.width - this.padRight, y);
      return this.ctx.stroke();
    }

    setCanvasSize() {
      var width;
      width = this.container.getBoundingClientRect().width;
      this.canvas.width = width;
      this.canvas.height = width / 2;
      this.width = this.canvas.width - this.padLeft - this.padRight;
      return this.height = this.canvas.height - this.padTop - this.padBottom;
    }

    priceToY(price) {
      return fit(price, this.maximum, this.minimum) * this.height + this.padTop;
    }

    draw() {
      var barHeight, barWidth, endAda, endPrice, endResultAda, endResultEur, endValue, f, fdt, fframe, fh, first, fresult, fresultWidth, ftrade, ftradeWidth, ftv, fx, fy, gap, i, last, offset, prec, range, s, scale, startAda, startPrice, summary, t, x, y;
      this.ctx = this.canvas.getContext('2d');
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.ctx.save();
      f = this.start + this.focus;
      // Draw scale lines
      range = this.maximum - this.minimum;
      scale = 10 ** (floor(log10(range)) - 1);
      first = ceil(this.minimum / scale) * scale;
      last = floor(this.maximum / scale) * scale;
      this.ctx.lineWidth = 0.5;
      this.ctx.fillStyle = LIGHT_GREY;
      this.ctx.font = REGULAR;
      this.ctx.textAlign = 'center';
      this.ctx.textBaseline = 'middle';
      prec = scale >= 1 ? 0 : abs(log10(scale));
      s = first;
      while (s <= last) {
        this.drawHorizLine(s, LIGHT_GREY);
        this.ctx.fillText(s.toFixed(prec), this.padLeft / 2, this.priceToY(s));
        s += scale;
      }
      this.ctx.textBaseline = 'alphabetic';
      // Draw bars
      gap = 0.1;
      barWidth = this.width / this.duration;
      offset = this.start;
      i = 0;
      while (i <= this.duration) {
        x = i * barWidth + this.padLeft;
        y = this.priceToY(this.frames[offset + i].mx);
        barHeight = this.priceToY(this.frames[offset + i].mn) - y;
        if (offset + i === f) {
          // Draw focus line
          this.ctx.fillStyle = GREY;
          this.ctx.fillRect(x, 0, barWidth, this.canvas.height);
          // Store focus values for later use
          fx = x + barWidth / 2;
          fy = y;
          fh = barHeight;
        }
        this.ctx.fillStyle = DARK_GREY;
        if (this.frames[offset + i].tv > 0) {
          this.ctx.fillStyle = GREEN;
        } else if (this.frames[offset + i].tv < 0) {
          this.ctx.fillStyle = RED;
        } else {
          this.ctx.fillStyle = DARK_GREY;
        }
        this.ctx.fillRect(x + barWidth * gap / 2, y, barWidth * (1 - gap), barHeight);
        this.ctx.fillStyle = DARK_GREY;
        i++;
      }
      fframe = this.frames[f];
      // Draw focus info
      this.ctx.fillStyle = DARK_GREY;
      this.ctx.font = BOLD;
      this.ctx.textAlign = 'center';
      // console.log(@start+@focus)
      fdt = (new Date(fframe.ft * 1000)).toDateString();
      ftv = fframe.tv;
      ftrade = (ftv > 0 ? 'Buy: ' : 'Sell: ') + (abs(ftv) / graph.frames[f].wa).toFixed(4) + ' for ' + abs(ftv).toFixed(2) + ' at ' + abs(fframe.wa).toFixed(2);
      ftradeWidth = FONTWIDTH * ftrade.length;
      fresult = fframe.adaval.toFixed(2) + '/' + fframe.eur.toFixed(2) + ' (' + (fframe.adaval + fframe.eur).toFixed(3) + ')';
      fresultWidth = FONTWIDTH * fresult.length;
      this.ctx.fillRect(fx - ftradeWidth / 2, fy - FONTHEIGHT - 20, ftradeWidth, FONTHEIGHT + 8);
      this.ctx.fillRect(fx - fresultWidth / 2, fy + fh + 12, fresultWidth, FONTHEIGHT + 8);
      this.ctx.fillStyle = ftv > 0 ? GREEN : RED;
      this.ctx.fillText(ftrade, fx, fy - 17);
      this.ctx.fillStyle = LIGHT_GREY;
      this.ctx.fillText(fresult, fx, fy + fh + 15 + FONTHEIGHT);
      this.ctx.fillStyle = DARK_GREY;
      this.ctx.fillText(fdt, this.canvas.width / 2, this.canvas.height - 15);
      // Draw top and bottom lines
      this.ctx.lineWidth = 1;
      this.drawHorizLine(this.bottom, GREEN);
      this.drawHorizLine(this.top, RED);
      this.drawHorizLine(Math.E ** ((log(this.bottom) + log(this.top)) / 2), BLUE);
      // Draw summary
      startPrice = parseFloat(this.frames[this.start].wa);
      startAda = this.initial / startPrice;
      endPrice = parseFloat(this.frames[this.start + this.duration].wa);
      endValue = this.frames[this.start + this.duration - 1].adaval + this.frames[this.start + this.duration - 1].eur;
      endAda = endValue / endPrice;
      endResultEur = endValue / this.initial;
      endResultAda = endAda / startAda;
      // console.log(typeof(startPrice))
      summary = 'Start price: ' + startPrice.toFixed(2) + ' Start ADA: ' + startAda.toFixed(2) + ' End price: ' + endPrice.toFixed(2) + ' (' + (endPrice / startPrice).toFixed(2) + ') End ADA:' + endAda.toFixed(2) + ' Result EUR: ' + endResultEur.toFixed(2) + ' Result ADA: ' + endResultAda.toFixed(2);
      this.ctx.fillStyle = DARK_GREY;
      this.ctx.fillText(summary, this.canvas.width / 2, 25);
      // FPS
      t = performance.now();
      this.ctx.font = REGULAR;
      this.ctx.textAlign = 'left';
      this.ctx.fillText(round(1000 / (t - timer)) + " FPS", 30, 30);
      timer = t;
      return this.ctx.restore();
    }

  };

  resizeAct = function() {
    graph.setCanvasSize();
    return redrawScreen();
  };

  wheelAct = function(e) {
    var delta, scale;
    if (e.shiftKey) {
      vp.rot += e.deltaY / 180 / vp.scale ** .5;
    } else {
      delta = e.deltaY * -0.01;
      scale = vp.scale * (1 + delta);
      scale = max(.001, min(1000, scale));
      vp.offx += (vp.width / 2 - e.clientX) * delta * vp.sep ** 2 / vp.unit;
      vp.offy += (vp.height / 2 - e.clientY) * delta * vp.sep ** 2 / vp.unit;
      vp.scale = scale;
      vp.update();
    }
    return redrawScreen();
  };

  mouseDownAct = function(e) {
    console.log("Pressed$ " + e.clientX);
    vp.panx = e.clientX;
    vp.pany = e.clientY;
    vp.panstx = vp.offx;
    vp.pansty = vp.offy;
    return vp.panning = true;
  };

  mouseUpAct = function(e) {
    return vp.panning = false;
  };

  redrawScreen = function() {
    return window.requestAnimationFrame(drawScreen);
  };

  drawScreen = function() {
    return graph.draw();
  };

  // Entry point. Just like that.
  graph = new Graph("doc_graph");

}).call(this);
