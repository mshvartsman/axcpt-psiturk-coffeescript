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

  updateBonusAndSave : ->
    psiTurk.saveData
      success: ->
        clearInterval reprompt
        psiTurk.computeBonus 'compute_bonus', ->
          finish()
          return
        return
      error: ->
        replaceBody "<h1>Oops!</h1><p>Something went wrong submitting your HIT. This might happen if you lose your internet connection. Press the button to resubmit.</p><button id='resubmit'>Resubmit</button>"
        $('#resubmit').click resubmit

  shuffleTrials: ->
    trialCounts = (td * @config.nTrials for td in @config.trialDist)
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

  endExperiment: (event) =>
    removeEventListener "keydown", @endExperiment
    @updateBonusAndSave()
    psiTurk.showPage('debriefing.html')

  endExperimentMoney: =>
    r.clearScreen()
    r.renderText "Congratulations! You have achieved the maximum possible bonus.\n
                  You will be paid $#{@config.minPayment + @config.maxBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}.\n
                  Please press any key to continue."
    psiTurk.recordUnstructuredData('expEndReason', 'maxMoney')
    addEventListener "keydown", @endExperiment
    

  endExperimentTrials: =>
    r.clearScreen()
    cashBonus = if @state.globalBonus < 0 then 0 else ExtMath.round(@state.globalBonus / @config.pointsPerDollar, 2)
    r.renderText "Thank you! This concludes the experiment.\n
                  Based on achieving #{ExtMath.round(@state.globalBonus,2)} points,\n
                  you will be paid $#{cashBonus} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}.\n
                  Please press any key to continue."
    psiTurk.recordUnstructuredData('expEndReason', 'trials')
    addEventListener "keydown", @endExperiment

  endExperimentFail: => 
    r.clearScreen()
    r.renderText "Unfortunately, you were unable to get #{@config.testStreakToPass} correct in a row.\n
                  This means that you cannot continue with the experiment.\n
                  You will receive $#{@config.minPayment} for your time.\n
                  If you have any questions, email #{@config.experimenterEmail}.\n
                  Please press any key to continue."
    addEventListener "keydown", @endExperiment

  startExperiment: ->
    @state.phase = "experiment"
    psiTurk.finishInstructions()
    @state.trialIdGlobal = 0 # reset so that trial IDs start at 0 uniformly
    @trialTypes[@trialOrder[0]].run()

  blockFeedback: ->
    r.clearScreen()
    # otherwise do feedback and next trial
    feedbackText = "Done with this block! \n Your bonus for this block was #{ExtMath.round(@state.blockBonus, 2)}!\n Your bonus for the experiment so far is #{ExtMath.round(@state.globalBonus, 2)}!\n Please take a short break.\n The experiment will continue in #{@config.blockRestDur} seconds."
    r.renderText feedbackText
    @state.blockBonus = 0
    setTimeout (=> @trialTypes[@trialOrder[@state.trialIdGlobal]].run(this)), @config.blockRestDur*1000
    @updateBonusAndSave()

  showInstructions: ->
    switch @state.instructionSlide
      when 0
        r.renderText "Welcome to the experiment!\n
                      In this experiment, you will make responses to pairs of stimuli.\n
                      The two stimuli in each pair will be separated by a blank screen.\n
                      There will be one correct response for each pair of stimuli.\n\n", "black", 0, -200
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 0 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 1
        r.clearScreen()
        r.renderText "First, you will learn the rules mapping stimuli to responses.\n
                      Then, we will test that you learned the mappings.\n
                      If you fail, the HIT will end and you will earn the minimum payment ($#{@config.minPayment}).\n
                      If you succeed, you will compete for an additional bonus of up to $#{@config.maxBonus}.\n
                      You response keys will be \"F\" (LEFT) and \"J\" (RIGHT). \n
                      You should put your left index finger on \"F\" and right index finger on \"J\" now. \n\n", "black", 0, -200
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 100 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 2
        r.clearScreen()
        r.renderText "Here is the first rule:\n
                      followed by      -->  hit the LEFT key\n
                      followed by      -->  hit the RIGHT key\n\n
                      Now you will get a chance to practice.", "black", 0, -200
        @renderStimInstruct @stimuli[0], "blue", -260, -165
        @renderStimInstruct @stimuli[1], "green", -60, -165
        @renderStimInstruct @stimuli[0], "blue", -260, -130
        @renderStimInstruct @stimuli[2], "green", -60, -130
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 0 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 3
        @state.phase = "APractice"
        @praxTrialTypes[@aPrax[0]].run()
      when 4
        r.clearScreen()
        r.renderText "Here is the second rule:\n
                      followed by      -->  hit the LEFT key\n
                      followed by      -->  hit the RIGHT key\n\n
                      Now you will get a chance to practice.", "black", 0, -200
        @renderStimInstruct @stimuli[3], "blue", -260, -165
        @renderStimInstruct @stimuli[2], "green", -60, -165
        @renderStimInstruct @stimuli[3], "blue", -260, -130
        @renderStimInstruct @stimuli[1], "green", -60, -130
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 0 ), @config.spacebarTimeout
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
                      As a reminder, here are the rules: \n", "black", 0, -200
        @renderRules(0, 60)
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 230 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 7
        r.clearScreen()
        @state.phase = "test"
        @testTrialTypes[@testTrialOrder[0]].run()
      when 8
        r.clearScreen()
        r.renderText "Congratulations! You have learned the rules.\n
                      You will now see up to #{@config.nTrials} more trials in blocks of #{@config.blockSize}.\n
                      You will get #{@config.correctPoints} points for a correct repsonse.\n
                      You will lose #{@config.inaccPenalty} points for a wrong response.\n
                      You will lose #{@config.penaltyPerSecond} points per second you take to respond. \n
                      If you do not respond in #{@config.deadline} seconds, you will lose #{@config.deadline*@config.penaltyPerSecond+@config.inaccPenalty} points.\n
                      That is, it is better to be right than wrong, and better to be fast than slow. \n
                      How much better is for you to figure out: try to get as many points as you can! \n
                      You will receive $1 for each #{@config.pointsPerDollar} points.\n
                      Your points can be negative but you cannot lose your $#{@config.minPayment} baseline.\n
                      The HIT will end when you have done #{@config.nTrials} trials total or earned #{@config.maxBonus*@config.pointsPerDollar} points.\n\n", "black", 0, -260
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 160 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 9
        r.clearScreen()
        r.renderText "As a reminder, here are the rules:", "black", 0, -200
        @renderRules(0, -150)
        setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 160 ), @config.spacebarTimeout
        setTimeout (=> addEventListener "keydown", @handleSpacebar), @config.spacebarTimeout
      when 10
        r.clearScreen()
        @startExperiment()

  renderRules : (xoffset=0, yoffset=0)->
    r.renderText "followed by      -->  hit the LEFT key\n
                  followed by      -->  hit the LEFT key\n
                  followed by      -->  hit the RIGHT key\n
                  followed by      -->  hit the RIGHT key", "black", xoffset, yoffset
    @renderStimInstruct e.stimuli[0], "blue", -280+xoffset, 105+yoffset
    @renderStimInstruct e.stimuli[2], "green", -60+xoffset, 105+yoffset
    @renderStimInstruct e.stimuli[0], "blue", -280+xoffset, 35+yoffset
    @renderStimInstruct e.stimuli[1], "green", -60+xoffset, 35+yoffset
    @renderStimInstruct e.stimuli[3], "blue", -280+xoffset, 70+yoffset
    @renderStimInstruct e.stimuli[1], "green", -60+xoffset, 70+yoffset
    @renderStimInstruct e.stimuli[3], "blue", -280+xoffset, 0+yoffset
    @renderStimInstruct e.stimuli[2], "green", -60+xoffset, 0+yoffset

  createTrialTypes: -> 
    @stimuli.shuffle() 
    @trialTypes = [new Trial("A", "X", @renderStimTrial, @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new Trial("A", "Y", @renderStimTrial, @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new Trial("B", "X", @renderStimTrial, @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new Trial("B", "Y", @renderStimTrial, @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @praxTrialTypes = [new PracticeTrial("A", "X", @renderStimTrial, @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new PracticeTrial("A", "Y", @renderStimTrial, @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new PracticeTrial("B", "X", @renderStimTrial, @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new PracticeTrial("B", "Y", @renderStimTrial, @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]

    @testTrialTypes = [new TestTrial("A", "X", @renderStimTrial, @stimuli[0], @stimuli[1], [70, 74], 70, "blue", "green"), 
                  new TestTrial("A", "Y", @renderStimTrial, @stimuli[0], @stimuli[2], [70, 74], 74, "blue", "green"), 
                  new TestTrial("B", "X", @renderStimTrial, @stimuli[3], @stimuli[1], [70, 74], 74, "blue", "green"),
                  new TestTrial("B", "Y", @renderStimTrial, @stimuli[3], @stimuli[2], [70, 74], 70, "blue", "green")]


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
  


class LettersExperiment extends Experiment  
  # @stimuli = ["A","X","B","Y"] # eventually this should be the whole alphabet
  stimuli: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

  renderStimInstruct : (stim, colour="black", xoffset=0, yoffset=0)->
    r.renderText stim, colour, xoffset, yoffset
  
  renderStimTrial : (stim, colour="black", xoffset=0, yoffset=0)=>
    r.renderText stim, colour, xoffset, yoffset, e.config.taskFontSize

class DotsExperiment extends Experiment  
  # all except 0000 which make it hard to see color
  # @stimuli : [[0,0,0,1],[0,0,1,0],[0,0,1,1],[0,1,0,0],[0,1,0,1],[0,1,1,0],[0,1,1,1],[1,0,0,0],[1,0,0,1],[1,0,1,0],[1,0,1,1],[1,1,0,0],[1,1,0,1],[1,1,1,0],[1,1,1,1]]
  # all with 2 empty 2 filled
  stimuli: [[0,0,1,1],[0,1,0,1],[0,1,1,0],[1,0,0,1],[1,0,1,0],[1,1,0,0]]

  renderStimInstruct : (stim, colour="black", xoffset=0, yoffset=0)->
    r.renderDots stim, colour, xoffset, yoffset, 5, 7
  
  renderStimTrial : (stim, colour="black", xoffset=0, yoffset=0)->
    r.renderDots stim, colour, xoffset, yoffset, 15, 20


# window.Experiment = LettersExperiment
window.Experiment = DotsExperiment
window.Renderer = Renderer

