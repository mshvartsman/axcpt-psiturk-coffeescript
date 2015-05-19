class Experiment
  state: null
  config: null

  constructor: (@config) ->
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
    @config.payoffId = 
    @createInitialState
    r.createDrawingContext()
    @createTrialTypes() 
    @shuffleTrials() 

  shuffleTrials: ->
    trialCounts = (td * @config.nTrials for td in @config.trialDist)
    # http://stackoverflow.com/questions/5685449/nested-array-comprehensions-in-coffeescript
    @trialOrder = [] 
    @trialOrder = (@trialOrder.concat i for [1..tc] for tc, i in trialCounts)
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
    r.clearScreen()
    switch @state.phase
      when "initialInstructions"
        @state.instructionSlide = 0
        @showInstructions()

      when "APractice"
        @state.aPraxId = @state.aPraxId + 1
        @state.trialIdGlobal = @state.trialIdGlobal + 1
        if (@state.aPraxId < @config.nPraxTrials)
          setTimeout (=> @praxTrialTypes[@aPrax[@state.aPraxId]].run()), @config.iti
        else 
          @state.instructionSlide = 4
          @showInstructions()

      when "BPractice"
        @state.bPraxId = @state.bPraxId + 1
        @state.trialIdGlobal = @state.trialIdGlobal + 1
        if (@state.bPraxId < @config.nPraxTrials) 
          setTimeout (=> @praxTrialTypes[@bPrax[@state.bPraxId]].run()), @config.iti
        else 
          @state.instructionSlide = 6
          @showInstructions()

      when "test"
        @state.testId = @state.testId + 1
        @state.trialIdGlobal = @state.trialIdGlobal + 1
        # if we've hit our streak
        if (@state.currentStreak is @config.testStreakToPass)
          psiTurk.recordUnstructuredData("trialsToLearn", @state.testId)
          @state.instructionSlide = 8
          @showInstructions() 
        # haven't hit streak but haven't run out of attempts
        else if (@state.testId < @config.nTestAttempts) 
          setTimeout (=> @testTrialTypes[@testTrialOrder[@state.testId]].run()), @config.iti
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
          @state.blockId = @state.blockId + 1
          @blockFeedback() 
        else 
          setTimeout (=> @trialTypes[@trialOrder[@state.trialIdGlobal]].run()), @config.iti

  endExperiment: ->
    psiTurk.saveData() 
    psiTurk.completeHIT()

  endExperimentMoney: ->
    r.clearScreen()
    r.renderText "Congratulations! You have achieved the maximum possible bonus.\n
                  You will be paid $#{@config.minPayment + @config.maxBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    # psiTurk.recordUnstructuredData('expEndReason', 'maxMoney')
    @endExperiment() 
    

  endExperimentTrials: ->
    r.clearScreen()
    cashBonus = if @state.globalBonus < 0 then 0 else ExtMath.round(@state.globalBonus / @config.pointsPerDollar, 2)
    r.renderText "Thank you! This concludes the experiment.\n
                  Based on achieving #{ExtMath.round(@state.globalBonus,2)} points,\n
                  you will be paid $#{cashBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    # psiTurk.recordUnstructuredData('expEndReason', 'trials')
    @endExperiment() 

  endExperimentFail: -> 
    r.clearScreen()
    r.renderText "Unfortunately, you were unable to get #{@config.testStreakToPass} correct in a row.\n
                  This means that you cannot continue with the experiment.\n
                  You will receive $#{@config.minPayment} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}\n
                  You may close this window now."
    psiTurk.saveData() 
    @endExperiment() 

  startExperiment: ->
    @state.phase = "experiment"
    psiTurk.finishInstructions()
    @state.trialIdGlobal = 0 # reset so that trial IDs start at 0 uniformly
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
                      The two stimuli in each pair will be separated by a blank screen.\n\n
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
    @stimuli = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    @stimuli.shuffle() 
    @trialTypes = [new Trial("A", "X", @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new Trial("A", "Y", @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new Trial("B", "X", @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new Trial("B", "Y", @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @praxTrialTypes = [new PracticeLetterTrial("A", "X", @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new PracticeLetterTrial("A", "Y", @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new PracticeLetterTrial("B", "X", @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new PracticeLetterTrial("B", "Y", @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @testTrialTypes = [new TestLetterTrial("A", "X", @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new TestLetterTrial("A", "Y", @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new TestLetterTrial("B", "X", @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new TestLetterTrial("B", "Y", @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]


    praxCounts = (@config.nPraxTrials/2 for i in [1..2]) # uniform distr of AX and AY or practice, BX and BY also
    # http://stackoverflow.com/questions/5685449/nested-array-comprehensions-in-coffeescript

    @aPrax = [] 
    @bPrax = []
    
    @aPrax = @aPrax.concat i for [1..pc] for pc, i in praxCounts

    @bPrax = @bPrax.concat i+2 for [1..pc] for pc, i in praxCounts # i+2 because B trials are trialtypes 2,3

    @aPrax.shuffle()
    @bPrax.shuffle()

    testCounts = (@config.nTestAttempts/4 for i in [1..4]) # uniform distr on all 4 for the test attempts
    @testTrialOrder = []
    @testTrialOrder = @testTrialOrder.concat i for [1..tc] for tc, i in testCounts
    @testTrialOrder.shuffle()


  showInstructions: ->
    switch @state.instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      In this experiment, you will make responses to pairs of stimuli.\n
                      The two stimuli in each pair will be separated by a blank screen.\n
                      There will be one correct response for each pair of stimuli.\n\n"
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 1
        r.clearScreen()
        r.renderText "First, you will learn the rules mapping stimuli to responses.\n
                      Then, we will test that you learned the mappings.\n
                      If you fail, the HIT will end and you will earn the minimum payment ($#{@config.minPayment}).\n
                      If you succeed, you will compete for an additional bonus of up to $#{@config.maxBonus}."
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 2
        r.clearScreen()
        r.renderText "Here is the first rule:\n
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"J\" key\n\n
                      Now you will get a chance to practice."
        r.renderText @stimuli[0], "blue", -240, 35
        r.renderText @stimuli[1], "green", -40, 35
        r.renderText @stimuli[0], "blue", -240, 75
        r.renderText @stimuli[2], "green", -40, 75
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 3
        @state.phase = "APractice"
        @praxTrialTypes[@aPrax[0]].run()
      when 4
        r.clearScreen()
        r.renderText "Here is the second rule:\n
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"J\" key\n\n
                      Now you will get a chance to practice."
        r.renderText @stimuli[3], "blue", -240, 35
        r.renderText @stimuli[2], "green", -40, 35
        r.renderText @stimuli[3], "blue", -240, 75
        r.renderText @stimuli[1], "green", -40, 75
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
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"J\" key\n
                      followed by      -->  hit the \"J\" key", "black", 0, -200
        r.renderText @stimuli[0], "blue", -240, 155
        r.renderText @stimuli[2], "green", -40, 155
        r.renderText @stimuli[0], "blue", -240, 80
        r.renderText @stimuli[1], "green", -40, 80
        r.renderText @stimuli[3], "blue", -240, 120
        r.renderText @stimuli[1], "green", -40, 120
        r.renderText @stimuli[3], "blue", -240, 45
        r.renderText @stimuli[2], "green", -40, 45
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 200 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 7
        r.clearScreen()
        @state.phase = "test"
        @testTrialTypes[@testTrialOrder[0]].run()
      when 8
        r.clearScreen()
        r.renderText "Congratulations! You have learned the rules.\n
                      You will now see up to #{@config.nTrials} more trials in blocks of #{@config.blockSize}.\n
                      You will get #{@config.correctBonus} points for a correct repsonse.\n
                      You will lose #{@config.inaccPenalty} points for a wrong response.\n
                      You will lose #{@config.penaltyPerSecond} points per second you take to respond. \n
                      If you do not respond in #{@config.deadline} seconds, you will lose #{@config.deadline*@config.penaltyPerSecond+@config.inaccPenalty} points.\n
                      That is, it is better to be right than wrong, and better to be fast than slow. \n
                      How much better is for you to figure out: try to get as many points as you can! \n
                      You will receive $1 for each #{@config.pointsPerDollar} points.\n
                      Your points can be negative but you cannot lose your $#{@config.minPayment} baseline.\n
                      The HIT will end when you have done #{@config.nTrials} trials total or earned #{@config.maxBonus*@config.pointsPerDollar} points.\n\n", "black", 0, -200
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 260 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 9
        r.clearScreen()
        r.renderText "As a reminder, here are the rules: \n
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"F\" key\n
                      followed by      -->  hit the \"J\" key\n
                      followed by      -->  hit the \"J\" key", "black", 0, -200
        r.renderText @stimuli[0], "blue", -240, 220
        r.renderText @stimuli[2], "green", -40, 220
        r.renderText @stimuli[0], "blue", -240, 150
        r.renderText @stimuli[1], "green", -40, 150
        r.renderText @stimuli[3], "blue", -240, 185
        r.renderText @stimuli[1], "green", -40, 185
        r.renderText @stimuli[3], "blue", -240, 115
        r.renderText @stimuli[2], "green", -40, 115
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 260 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 10
        r.clearScreen()
        @startExperiment()
    

window.Experiment = LettersExperiment
# window.Experiment = DotsExperiment
window.Renderer = Renderer

