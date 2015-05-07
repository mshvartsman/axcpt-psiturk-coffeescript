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



class Experiment
  expState: null
  instructionSlide: 0
  spacebarTimeout : 100

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
                  new DotsTrial(@stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new DotsTrial(@stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new DotsTrial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]
    
  showInstructions: ->
    switch @instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      In this experiment, you will make responses to pairs of stimuli.\n
                      The pairs will be separated by a blank screen.\n\n
                      Press the spacebar to continue."
        addEventListener "keydown", @handleSpacebar
      when 1
        r.clearScreen()
        r.renderText "If you see the symbol    followed by the symbol    , hit the \"F\" Key.\n
                      Do the same if you see the symbol    followed by the symbol    \n\n
                      But if you see the symbol    followed by the symbol    \n
                      or the symbol    followed by the symbol    , hit the \"J\" Key.\n\n
                      Press the spacebar to continue."
        # contexts
        r.renderDots @stimuli[0], "blue", -132.5, -7.5 , 4, 5
        r.renderDots @stimuli[3], "blue", 67, 28 , 4, 5
        r.renderDots @stimuli[0], "blue", 3, 98 , 4, 5
        r.renderDots @stimuli[3], "blue", -178, 133 , 4, 5
        # targets
        r.renderDots @stimuli[1], "green", 210, -7.5 , 4, 5
        r.renderDots @stimuli[2], "green", 400, 28 , 4, 5
        r.renderDots @stimuli[2], "green", 340, 98 , 4, 5
        r.renderDots @stimuli[1], "green", 165, 133 , 4, 5
        addEventListener "keydown", @handleSpacebar
      when 2
        r.clearScreen()
        @expState.startExperiment()
  

class LettersExperiment extends Experiment  
    
  createTrialTypes: -> 
    # @stimuli = ["A","X","B","Y"] # eventually this should be the whole alphabet
    @stimuli = ["A", "B", "C", "D", "E", "F", "G"]
    @stimuli.shuffle() 
    @trialTypes = [new Trial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new Trial(@stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new Trial(@stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new Trial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

  showInstructions: ->
    switch @instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      In this experiment, you will make responses to pairs of stimuli.\n
                      The pairs will be separated by a blank screen.\n
                      There will be rules mapping from the stimuli pairs to the response you make.\n\n"
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @spacebarTimeout
      when 1
        r.clearScreen()
        r.renderText "First, you will learn the rules mapping stimuli to responses.\n
                      Then, we will test that you learned the mappings.\n
                      If you fail, you the HIT will finish and you will earn the minimum payment.\n
                      If you succeed, you will be able to compete for a bonus of up to $5."
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @spacebarTimeout
      when 2
        r.clearScreen()
        r.renderText "Here is the    rule:\n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"J\" key\n\n
                      Now you will get a chance to practice."
        r.renderText @stimuli[0], "blue", 45, 0
        r.renderText @stimuli[0], "blue", -180, 35
        r.renderText @stimuli[1], "green", -100, 35
        r.renderText @stimuli[0], "blue", -180, 75
        r.renderText @stimuli[2], "green", -100, 75
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @spacebarTimeout
      when 3
        @expState.runAPractice()
      when 4
        r.clearScreen()
        r.renderText "Here is the second rule:\n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"J\" key\n\n
                      Now you will get a chance to practice."
        r.renderText @stimuli[0], "blue", -180, 35
        r.renderText @stimuli[2], "green", -100, 35
        r.renderText @stimuli[3], "blue", -180, 75
        r.renderText @stimuli[1], "green", -100, 75
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @spacebarTimeout
      when 5
        @expState.runBPractice()
      when 4
        r.clearScreen()
        @expState.startExperiment()
    

# window.Experiment = LettersExperiment
window.Experiment = DotsExperiment
window.Renderer = Renderer

r = new Renderer()