# inspired by http://www.calicowebdev.com/2011/05/01/simple-coffeescript-introduction/
class ExtMath extends Math
  @round = (x, precision = 0) ->
    scale = 10 ** precision
    Math.round(x * scale) / scale

# https://coffeescript-cookbook.github.io/chapters/arrays/shuffling-array-elements
Array::shuffle ?= ->
  if @length > 1 then for i in [@length-1..1]
    j = Math.floor Math.random() * (i + 1)
    [@[i], @[j]] = [@[j], @[i]]
  this

class Renderer
  drawingContext: null

  constructor: (@config) ->


  createDrawingContext: () ->
    @canvas = document.createElement 'canvas'
    document.body.appendChild @canvas
    @canvas.style.display = "block"
    @canvas.style.margin = "0 auto"
    @canvas.style.padding = "0"
    @canvas.width = 1024
    @canvas.height = 768
    @drawingContext = @canvas.getContext '2d'
    @drawingContext.font = "#{@config.instructionFontSize}px #{@config.fontFamily}"
    # @drawingContext.font = "30px sans-serif"
    @drawingContext.textAlign = "center"

  renderText: (text, color="black", shiftx=0, shifty=0, size) ->
    size ?= e.config.instructionFontSize
    @drawingContext.font = "#{size}px #{@config.fontFamily} "
    @fillTextMultiLine(@drawingContext, text, @canvas.width/2+shiftx, @canvas.height/2+shifty, color)

  fillTextMultiLine: (ctx, text, x, y, color) ->
    lineHeight = ctx.measureText("M").width * 1.4
    lines = text.split("\n")
    ctx.fillStyle = color
    for line in lines
      ctx.fillText(line, x, y)
      y += lineHeight

  renderCircle: (x, y, radius, fill=true, color="black") ->
    @drawingContext.strokeStyle = 'color'
    @drawingContext.beginPath()
    @drawingContext.arc(x, y, radius, 0, 2 * Math.PI, false)
    @drawingContext.fillStyle = 'white'
    if (fill)
      @drawingContext.fillStyle = color
      @drawingContext.fill()
    @drawingContext.lineWidth = 1
    # @drawingContext.strokeStyle = 'color'
    @drawingContext.stroke() 

  renderDots: (stim, color="black", shiftX = 0, shiftY = 0, radius=10, sep=20) ->
    centerx = @canvas.width/2 + shiftX
    centery = @canvas.height/2 + shiftY - sep # shift things up to make these appear exactly where the letters do
    offsets = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
    for offset, i in offsets
      @renderCircle centerx+offset[0]*sep, centery+offset[1]*sep, radius, stim[i], color

  clearScreen: =>
    @drawingContext.clearRect(0,0, @canvas.width, @canvas.height)
