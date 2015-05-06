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


class State
  blockId : 0
  trialIdBlock : 0
  trialIdGlobal : 0
  blockBonus: 0
  globalBonus: 0

  constructor: (@config) ->

  startExperiment: () ->
    @config.trialTypes[@config.trialOrder[@trialIdGlobal]].run(this)

  endExperiment: ->
    psiTurk.saveData()

  blockFeedback: ->
    if @blockId > (@config.nBlocks-1) # blocks are 0-indexed
      # if block is past nblocks, end the experiment
      @endExperiment()
      r.clearScreen()
      r.renderText "DONE!"
    else  
      r.clearScreen()
      # otherwise do feedback and next trial
      feedbackText = "Done with this block! ! \n Your bonus for this block was #{ExtMath.round(@blockBonus, 2)}!\n Your bonus for the experiment so far is #{ExtMath.round(@globalBonus, 2)}!\n Please take a short break.\n The experiment will continue in 10 seconds."
      r.renderText feedbackText
      @blockBonus = 0
      setTimeout (=> @config.trialTypes[@config.trialOrder[@trialIdGlobal]].run(this)), 10000

  runNextTrial : () -> 
    # increment trial global 
    @trialIdGlobal = @trialIdGlobal + 1
    # increment trial block
    @trialIdBlock = @trialIdBlock + 1
    # if trial block is past blocksize, increment block and reset trialIdBlock
    if @trialIdBlock >= @config.blockSize
      @trialIdBlock = 0
      @blockId = @blockId + 1
      @blockFeedback() # this guy also runs the next trial if needed
    else # otherwise run next trial
      @config.trialTypes[@config.trialOrder[@trialIdGlobal]].run(this)

class Trial
  startTime: null
  rt: null
  acc: null
  bonus: null
  next: null
  timeout: null
  myState: null

  handleSpacebar: (event) =>
    if event.keyCode is 32
      removeEventListener "keydown", @handleSpacebar
      @myState.runNextTrial()

  handleButtonPress: (event) =>
    if event.keyCode in @keys # it's one of our legal responses
      removeEventListener "keydown", @handleButtonPress
      @rt = performance.now() - @startTime
      @acc = if event.keyCode == @cresp then 1 else 0
      @computeBonus() 
      clearTimeout @timeout
      psiTurk.recordTrialData [@trialIdGlobal, @trialIdBlock, @blockID, @context, @target, @cresp, @rt, @acc, @bonus]
      @showFeedback()

  constructor:(@context, @target, @keys, @cresp, @contextColor="black", @targetColor="black", @timeoutDur=10000)-> 

  computeBonus: => 
    @bonus = if @acc is 1 then 100 else -50 
    @bonus = @bonus - @rt * 0.1
    @myState.blockBonus = @myState.blockBonus + @bonus
    @myState.globalBonus = @myState.globalBonus + @bonus

  run: (state) => 
    @myState = state # hang onto state
    r.clearScreen() 
    @startTime = performance.now() + @myState.config.iti + @myState.config.contextDur
    r.renderText @context, @contextColor
    setTimeout r.clearScreen, @myState.config.contextDur
    setTimeout (=> r.renderText @target, @targetColor), @myState.config.iti + @myState.config.contextDur
    setTimeout @enableInput, @myState.config.iti+@myState.config.contextDur
    
  timedOut: =>
    r.clearScreen()
    r.renderText "Timed out! -300 points! Press spacebar to continue."
    psiTurk.recordTrialData {'myID': @myID, 'context': @context, 'target': @target, 'cresp': @cresp, 'rt': @rt, 'acc': @acc, 'bonus': @bonus}
    addEventListener "keydown", @handleSpacebar

  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
        feedbackText = "Correct! \n Your RT was #{ExtMath.round(@rt, 2)}ms! \n You get #{ExtMath.round(@bonus, 2)} points! \n\n Press the spacebar to continue."
    else 
        feedbackText = "Wrong! \n Your RT was #{ExtMath.round(@rt,2)}ms! \n You get #{ExtMath.round(@bonus,2)} points! \n\n Press the spacebar to continue."
    r.renderText feedbackText
    addEventListener "keydown", @handleSpacebar


  enableInput: =>
    addEventListener "keydown", @handleButtonPress
    @timeout = setTimeout @timedOut, @timeoutDur

class DotsTrial extends Trial
  constructor: (@context, @target, @keys, @cresp, @contextColor="black", @targetColor="black", @timeoutDur=10000)->
    console.log @contextColor
    super(@context, @target, @keys, @cresp, @contextColor, @targetColor, @timeoutDur=10000)

  run: (state) =>
    @myState = state # hang onto state
    r.clearScreen() 
    @startTime = performance.now() + @myState.config.iti + @myState.config.contextDur
    r.renderDots @context, @contextColor
    setTimeout r.clearScreen, @myState.config.contextDur
    setTimeout (=> r.renderDots @target, @targetColor), @myState.config.iti + @myState.config.contextDur
    setTimeout @enableInput, @myState.config.iti+@myState.config.contextDur

class Renderer
  drawingContext: null

  createDrawingContext: (fontParams) ->
    @canvas = document.createElement 'canvas'
    document.body.appendChild @canvas
    @canvas.style.display = "block"
    @canvas.style.margin = "0 auto"
    @canvas.style.padding = "0"
    @canvas.width = 1024
    @canvas.height = 768
    @drawingContext = @canvas.getContext '2d'
    @drawingContext.font = fontParams
    @drawingContext.textAlign = "center"

  renderText: (text, color="black") ->
    @fillTextMultiLine(@drawingContext, text, @canvas.width/2, @canvas.height/2, color)

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
    centerx = @canvas.width/2
    centery = @canvas.height/2
    offsets = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
    for offset, i in offsets
      @renderCircle centerx+offset[0]*sep+shiftX, centery+offset[1]*sep+shiftY, radius, stim[i], color

  clearScreen: =>
    @drawingContext.clearRect(0,0, @canvas.width, @canvas.height)

class Experiment
  expState: null
  instructionSlide: 0

  constructor: (@trialDist = [0.5, 0.2, 0.2, 0.1], @nTrials=10, @fontParams = "30px sans-serif") ->
    @createInitialState
    r.createDrawingContext(@fontParams)
    @createTrialTypes() 
    @shuffleTrials() 

  shuffleTrials: ->
    trialCounts = (td * @nTrials for td in @trialDist)
    # http://stackoverflow.com/questions/5685449/nested-array-comprehensions-in-coffeescript
    @trialOrder = [] 
    @trialOrder = @trialOrder.concat i for [1..tc] for tc, i in trialCounts
    @trialOrder.shuffle()

  handleSpacebar: (event) =>
    if event.keyCode is 32
      removeEventListener "keydown", @handleSpacebar
      @instructionSlide = @instructionSlide + 1 
      @showInstructions()

  run: ->
    config = 
      blockSize: 5
      nBlocks: 2
      trialTypes: @trialTypes
      trialOrder: @trialOrder
      contextDur: 500
      iti: 2000
      targetDurMax: 10000
      

    @expState = new State(config)

    @showInstructions()


class DotsExperiment extends Experiment
  # exclude 0000 because it's harder to see the color there
  stimuli : [[0,0,0,1],[0,0,1,0],[0,0,1,1],[0,1,0,0],[0,1,0,1],[0,1,1,0],[0,1,1,1],[1,0,0,0],[1,0,0,1],[1,0,1,0],[1,0,1,1],[1,1,0,0],[1,1,0,1],[1,1,1,0],[1,1,1,1]]

  createTrialTypes: -> 
    
    @stimuli.shuffle() # we're going to use the first 4 only
    @trialTypes = [new DotsTrial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new DotsTrial(@stimuli[0], @stimuli[2], [70, 74], 70, "blue", "green"), 
                  new DotsTrial(@stimuli[3], @stimuli[1], [70, 74], 70, "blue", "green"),
                  new DotsTrial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]
    
  showInstructions: ->
    switch @instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      I this experiment, you will make responses to pairs of stimuli.\n
                      The pairs will be separated by a blank screen.\n\n
                      Press the spacebar to continue."
        addEventListener "keydown", @handleSpacebar
      when 1
        r.clearScreen()
        r.renderText "If you see the symbol   followed by the symbol  , hit the \"F\" Key.\n
                      Do the same if you see the symbol   followed by the symbol  .\n\n
                      But if you see the symbol   followed by the symbol  \n
                      or the symbol   followed by the symbol  , hit the \"J\" Key.\n\n
                      Press the spacebar to continue."
        r.renderDots @stimuli[0], "red", -100, -100, 5, 5
        addEventListener "keydown", @handleSpacebar
      when 2
        r.clearScreen()
        @expState.startExperiment()
  

class LettersExperiment extends Experiment  
    
  createTrialTypes: -> 
    @stimuli = ["A","X","B","Y"] # eventually this should be the whole alphabet
    @stimuli.shuffle() 
    @trialTypes = [new Trial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new Trial(@stimuli[0], @stimuli[2], [70, 74], 70, "blue", "green"), 
                  new Trial(@stimuli[3], @stimuli[1], [70, 74], 70, "blue", "green"),
                  new Trial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

  showInstructions: ->
    switch @instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      I this experiment, you will make responses to pairs of stimuli.\n
                      The pairs will be separated by a blank screen.\n\n
                      Press the spacebar to continue."
        addEventListener "keydown", @handleSpacebar
      when 1
        r.clearScreen()
        r.renderText "If you see the letter #{@stimuli[0]} followed by the letter #{@stimuli[1]}, hit the \"F\" Key.\n
                      Do the same if you see the letter #{@stimuli[3]} followed by the letter #{@stimuli[2]}.\n\n
                      But if you see the letter #{@stimuli[0]} followed by the letter #{@stimuli[2]}\n
                      or the letter #{@stimuli[3]} followed by the letter #{@stimuli[1]}, hit the \"J\" Key.\n\n
                      Press the spacebar to continue."
        addEventListener "keydown", @handleSpacebar
      when 2
        r.clearScreen()
        @expState.startExperiment()
    

# window.Experiment = LettersExperiment
window.Experiment = DotsExperiment
window.Renderer = Renderer

r = new Renderer()