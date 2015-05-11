class Experiment
  state: null
  config: null

  constructor: (@trialDist = [0.5, 0.2, 0.2, 0.1], @fontParams = "30px sans-serif") ->
    @config = 
      blockSize: 5
      nBlocks: 2
      contextDur: 10
      iti: 10
      targetDurMax: 10000
      spacebarTimeout: 100
      blockRestDur: 1
      nPraxTrials: 0
      nTestAttempts: 10
      testStreakToPass: 1
      minPayment: 1
      maxBonus: 5
      correctPointsPerSec: 5
      incorrectPointsPerSec: 5
      deadline: 5
      pointsPerDollar: 500
      experimenterEmail: "pni.nccl.mturk@gmail.com"

    @state = 
      blockId : 0
      trialIdGlobal : 0 
      aPraxId: 0
      bPraxId: 0
      testId: 0
      blockBonus: 0
      globalBonus: 0
      currentStreak: 0
      phase: "initialInstructions"

    @config.nTrials = @config.blockSize * @config.nBlocks
    @createInitialState
    r.createDrawingContext(@fontParams)
    @createTrialTypes() 
    @shuffleTrials() 

  shuffleTrials: ->
    trialCounts = (td * @config.nTrials for td in @trialDist)
    # http://stackoverflow.com/questions/5685449/nested-array-comprehensions-in-coffeescript
    @trialOrder = [] 
    @trialOrder = @trialOrder.concat i for [1..tc] for tc, i in trialCounts
    @trialOrder.shuffle()

  handleSpacebar: (event) =>
    if event.keyCode is 32
      removeEventListener "keydown", @handleSpacebar
      @state.instructionSlide = @state.instructionSlide + 1 
      @showInstructions()

  setState: (state) ->
    @state = state

  run: ->

    @doNext() 

  doNext: ->
    switch @state.phase
      when "initialInstructions"
        @state.instructionSlide = 0
        @showInstructions()

      when "APractice"
        @state.aPraxId = @state.aPraxId + 1
        if (@state.aPraxId <= @config.nPraxTrials)
          @praxTrialTypes[@aPrax[@state.aPraxId]].run()
        else 
          @state.instructionSlide = 4
          @showInstructions()

      when "BPractice"
        @state.bPraxId = @state.bPraxId + 1
        if (@state.bPraxId < @config.nPraxTrials) 
          @praxTrialTypes[@bPrax[@state.bPraxId]].run()
        else 
          @state.instructionSlide = 6
          @showInstructions()

      when "test"
        @state.testId = @state.testId + 1
        # if we've hit our streak
        if (@state.currentStreak is @config.testStreakToPass)
          @state.instructionSlide = 8
          @showInstructions() 
        # haven't hit streak but haven't run out of attempts
        else if (@state.testId < @config.nTestAttempts) 
          @testTrialTypes[@testTrialOrder[@state.testId]].run()
        # ran out of attempts
        else 
          @endExperimentFail()

      when "experiment"
        @state.trialIdGlobal = @state.trialIdGlobal + 1
        if (@state.trialIdGlobal is @config.nTrials)
          @endExperimentTrials()
        else if ((@state.globalBonus/@config.pointsPerDollar) >= @config.maxBonus)
          @endExperimentMoney()
        else if ((@state.trialIdGlobal %% @config.blockSize) is 0) 
          @blockFeedback() 
        else 
          @trialTypes[@trialOrder[@state.trialIdGlobal]].run()

  endExperimentMoney: ->
    r.clearScreen()
    r.renderText "Congratulations! You have achieved the maximum possible bonus.\n
                  You will be paid $#{@config.minPayment + @config.maxBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    psiTurk.saveData() 
    console.log "pay and record here"

  endExperimentTrials: ->
    r.clearScreen()
    cashBonus = if @state.globalBonus < 0 then 0 else ExtMath.round(@state.globalBonus / @config.pointsPerDollar, 2)
    r.renderText "Thank you! This concludes the experiment.\n
                  Based on achieving #{ExtMath.round(@state.globalBonus,2)} points,\n
                  you will be paid $#{cashBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    psiTurk.saveData() 
    console.log "pay and record here"

  endExperimentFail: -> 
    r.clearScreen()
    r.renderText "Unfortunately, you were unable to get #{@config.testStreakToPass} correct in a row.\n
                  This means that you cannot continue with the experiment.\n
                  You will receive $#{@config.minPayment} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    psiTurk.saveData() 
    console.log "pay and record here"

  startExperiment: ->
    @state.phase = "experiment"
    @trialTypes[@trialOrder[0]].run()

  blockFeedback: ->
    r.clearScreen()
    # otherwise do feedback and next trial
    feedbackText = "Done with this block! ! \n Your bonus for this block was #{ExtMath.round(@state.blockBonus, 2)}!\n Your bonus for the experiment so far is #{ExtMath.round(@state.globalBonus, 2)}!\n Please take a short break.\n The experiment will continue in #{@config.blockRestDur} seconds."
    r.renderText feedbackText
    @state.blockBonus = 0
    setTimeout (=> @trialTypes[@trialOrder[@state.trialIdGlobal]].run(this)), @config.blockRestDur*1000
    psiTurk.saveData() 


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
        @state.startExperiment()
  

class LettersExperiment extends Experiment  
    
  createTrialTypes: -> 
    # @stimuli = ["A","X","B","Y"] # eventually this should be the whole alphabet
    @stimuli = ["A", "B", "C", "D", "E", "F", "G"]
    @stimuli.shuffle() 
    @trialTypes = [new Trial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new Trial(@stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new Trial(@stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new Trial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @praxTrialTypes = [new PracticeLetterTrial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new PracticeLetterTrial(@stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new PracticeLetterTrial(@stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new PracticeLetterTrial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @testTrialTypes = [new TestLetterTrial(@stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new TestLetterTrial(@stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new TestLetterTrial(@stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new TestLetterTrial(@stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]


    praxCounts = (@config.nPraxTrials/2 for i in [1..2]) # uniform distr of AX and AY or practice, BX and BY also
    # http://stackoverflow.com/questions/5685449/nested-array-comprehensions-in-coffeescript

    @aPrax = [] 
    @bPrax = []

    @aPrax = @aPrax.concat i for [1..pc] for pc, i in praxCounts
    @bPrax = @bPrax.concat i for [1..pc] for pc, i in praxCounts
    @aPrax.shuffle()
    @bPrax.shuffle()

    testCounts = (@config.nTestAttempts/4 for i in [1..4]) # uniform distr on all 4 for the test attempts
    @testTrialOrder = []
    @testTrialOrder = @testTrialOrder.concat i for [1..pc] for tc, i in testCounts
    @testTrialOrder.shuffle()


  showInstructions: ->
    switch @state.instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      In this experiment, you will make responses to pairs of stimuli.\n
                      The pairs will be separated by a blank screen.\n
                      There will be rules mapping from the stimuli pairs to the response you make.\n\n"
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 1
        r.clearScreen()
        r.renderText "First, you will learn the rules mapping stimuli to responses.\n
                      Then, we will test that you learned the mappings.\n
                      If you fail, you the HIT will finish and you will earn the minimum payment ($#{@config.minPayment}).\n
                      If you succeed, you will compete for an additional bonus of up to $#{@config.maxBonus}."
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
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
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 3
        @state.phase = "APractice"
        @praxTrialTypes[@aPrax[0]].run()
      when 4
        r.clearScreen()
        r.renderText "Here is the    rule:\n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"J\" key\n\n
                      Now you will get a chance to practice."
        r.renderText @stimuli[3], "blue", 45, 0
        r.renderText @stimuli[3], "blue", -180, 35
        r.renderText @stimuli[1], "green", -100, 35
        r.renderText @stimuli[3], "blue", -180, 75
        r.renderText @stimuli[2], "green", -100, 75
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 5
        @state.phase = "BPractice"
        @praxTrialTypes[@bPrax[0]].run()
      when 6
        r.clearScreen()
        r.renderText "Now, we will test that you have learned the rules.\n
                      You will see a sequence of trials. Your goal is to get #{@config.testStreakToPass} correct in a row.\n
                      You will have #{@config.nTestAttempts} trials total. If you get #{@config.testStreakToPass} correct in a row, you can compete\n
                      for a bonus of up to $#{@config.maxBonus}. If you get to #{@config.nTestAttempts} without getting #{@config.testStreakToPass} in a row, \n
                      the HIT will end and you will get the minimum payment ($#{@config.minPayment}).\n\n
                      As a reminder, here are the rules: \n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"J\" key\n
                      +      -->  hit the \"J\" key", "black", 0, -200
        r.renderText @stimuli[0], "blue", -180, 155
        r.renderText @stimuli[2], "green", -100, 155
        r.renderText @stimuli[0], "blue", -180, 80
        r.renderText @stimuli[1], "green", -100, 80
        r.renderText @stimuli[3], "blue", -180, 120
        r.renderText @stimuli[1], "green", -100, 120
        r.renderText @stimuli[3], "blue", -180, 45
        r.renderText @stimuli[2], "green", -100, 45
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 7
        r.clearScreen()
        @state.phase = "test"
        @testTrialTypes[@testTrialOrder[0]].run()
      when 8
        r.clearScreen()
        r.renderText "Congratulations! You have learned the rules.\n
                      You will now see up to #{@config.nTrials} more trials in blocks of #{@config.blockSize}. \n
                      You will receive #{@config.correctPointsPerSec} points per second under #{@config.deadline}s on a correct response.\n
                      You will receive #{@config.incorrectPointsPerSec} points per second under #{@config.deadline}s on an incorrect response.\n
                      You will receive $1 for each #{@config.pointsPerDollar} points.\n
                      The HIT will end when you have done #{@config.nTrials} trials total or earned #{@config.maxBonus*@config.pointsPerDollar} points.\n\n
                      As a reminder, here are the rules: \n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"F\" key\n
                      +      -->  hit the \"J\" key\n
                      +      -->  hit the \"J\" key", "black", 0, -200
        r.renderText @stimuli[0], "blue", -180, 190
        r.renderText @stimuli[2], "green", -100, 190
        r.renderText @stimuli[0], "blue", -180, 120
        r.renderText @stimuli[1], "green", -100, 120
        r.renderText @stimuli[3], "blue", -180, 155
        r.renderText @stimuli[1], "green", -100, 155
        r.renderText @stimuli[3], "blue", -180, 80
        r.renderText @stimuli[2], "green", -100, 80
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 230 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 9
        r.clearScreen()
        @startExperiment()
    

window.Experiment = LettersExperiment
# window.Experiment = DotsExperiment
window.Renderer = Renderer

r = new Renderer()