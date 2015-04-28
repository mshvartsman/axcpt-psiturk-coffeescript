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

  constructor:(@context, @target, @keys, @cresp, @timeoutDur = 10000)-> 

  computeBonus: => 
    @bonus = if @acc is 1 then 100 else -50 
    @bonus = @bonus - @rt * 0.1
    @myState.blockBonus = @myState.blockBonus + @bonus
    @myState.globalBonus = @myState.globalBonus + @bonus

  run: (state) => 
    @myState = state # hang onto state
    r.clearScreen() 
    @startTime = performance.now() + @myState.config.iti + @myState.config.contextDur
    r.renderText @context
    setTimeout r.clearScreen, @myState.config.contextDur
    setTimeout (=> r.renderText @target), @myState.config.iti + @myState.config.contextDur
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
  constructor: (@context, @target, @keys, @cresp, @timeoutDur=10000)->
    super("Q", "W", @keys, @cresp, @timeoutDur=10000)

  run: (state) =>
    @myState = state # hang onto state
    r.clearScreen() 
    @startTime = performance.now() + @myState.config.iti + @myState.config.contextDur
    r.renderDots 3
    setTimeout r.clearScreen, @myState.config.contextDur
    setTimeout (=> r.renderDots 3, false), @myState.config.iti + @myState.config.contextDur
    setTimeout @enableInput, @myState.config.iti+@myState.config.contextDur

class Renderer
  drawingContext: null

  createDrawingContext: (fontParams) ->
    @canvas = document.createElement 'canvas'
    document.body.appendChild @canvas
    @canvas.style.display = "block"
    @canvas.style.margin = "0 auto"
    @canvas.style.padding = "0"
    @canvas.width = 800
    @canvas.height = 600
    @drawingContext = @canvas.getContext '2d'
    @drawingContext.font = fontParams
    @drawingContext.textAlign = "center"

  renderText: (text) ->
    @fillTextMultiLine(@drawingContext, text, 400, 300)

  fillTextMultiLine: (ctx, text, x, y) ->
    lineHeight = ctx.measureText("M").width * 1.4
    lines = text.split("\n")
    for line in lines
      ctx.fillText(line, x, y)
      y += lineHeight

  renderCircle: (x, y, radius, fill=true) ->
    @drawingContext.beginPath()
    @drawingContext.arc(x, y, radius, 0, 2 * Math.PI, false)
    @drawingContext.fillStyle = 'white'
    if (fill==true)
      @drawingContext.fillStyle = 'black'
      @drawingContext.fill()
    @drawingContext.lineWidth = 1
    @drawingContext.strokeStyle = 'black'
    @drawingContext.stroke() 

  renderDots: (stimID) ->
    for coord in dotLocs
      @renderCircle coord[0], coord[1], 10, true

  clearScreen: =>
    @drawingContext.clearRect(0,0, 800, 600)

class Experiment

  expState: null

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
    
  createTrialTypes: -> 
    stimuli = ["A","X","B","Y"]
    stimuli.shuffle() 
    @trialTypes = [new Trial(stimuli[0], stimuli[1], [70, 74], 70), 
                  new Trial(stimuli[0], stimuli[2], [70, 74], 70), 
                  new Trial(stimuli[3], stimuli[1], [70, 74], 70),
                  new Trial(stimuli[3], stimuli[2], [70, 74], 70)]
  
    # @trialTypes = [new DotsTrial(0, 0, [70, 74], 70), 
    #               new DotsTrial(0, 1, [70, 74], 70), 
    #               new DotsTrial(1, 0, [70, 74], 70),
    #               new DotsTrial(1, 1, [70, 74], 70)]
    

  showInstructions: ->
    r.renderText "We are instructions."
    addEventListener "keydown", @handleSpacebar
    

  handleSpacebar: (event) =>
    if event.keyCode is 32
      removeEventListener "keydown", @handleSpacebar
      @expState.startExperiment()


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

    

dotLocs =  [[380, 280], [380, 320], [420, 280], [420, 320]]

window.Experiment = Experiment
window.Renderer = Renderer

r = new Renderer()