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
      e.doNext()

  recordTrial: () =>
    psiTurk.recordTrialData {"trialId":e.state.trialIdGlobal, "blockID":e.state.blockId, "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":@bonus}

  handleButtonPress: (event) =>
    if event.keyCode in @keys # it's one of our legal responses
      removeEventListener "keydown", @handleButtonPress
      @rt = performance.now() - @startTime
      @acc = if event.keyCode == @cresp then 1 else 0
      @computeBonus() 
      clearTimeout @timeout
      @recordTrial() 
      @showFeedback()

  constructor:(@context, @target, @contextItem, @targetItem, @keys, @cresp, @contextColor="black", @targetColor="black")-> 

  computeBonus: => 
    if @acc is 1
      @bonus = (e.config.deadline-(@rt/1000))*e.config.correctPointsPerSec
    else 
      @bonus = @rt/1000 * e.config.incorrectPointsPerSec
    e.state.blockBonus = e.state.blockBonus + @bonus
    e.state.globalBonus = e.state.globalBonus + @bonus

  run: (state) => 
    r.clearScreen() 
    @startTime = performance.now() + e.config.iti + e.config.contextDur
    r.renderText @contextItem, @contextColor
    setTimeout r.clearScreen, e.config.contextDur
    setTimeout (=> r.renderText @targetItem, @targetColor), e.config.iti + e.config.contextDur
    setTimeout @enableInput, e.config.iti + e.config.contextDur
    
  timedOut: =>
    r.clearScreen()
    r.renderText "Timed out! Press spacebar to continue."
    @recordTrial()
    addEventListener "keydown", @handleSpacebar

  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
        feedbackText = "Correct! \n Your RT was #{ExtMath.round(@rt, 2)}ms! \n You get #{ExtMath.round(@bonus, 2)} points! \n\n Press the spacebar to continue."
    else 
        feedbackText = "Incorrect! \n Your RT was #{ExtMath.round(@rt,2)}ms! \n You get #{ExtMath.round(@bonus,2)} points! \n\n Press the spacebar to continue."
    r.renderText feedbackText
    addEventListener "keydown", @handleSpacebar


  enableInput: =>
    addEventListener "keydown", @handleButtonPress
    @timeout = setTimeout @timedOut, e.config.deadline*1000

class PracticeLetterTrial extends Trial
  # remove timeout
  enableInput: => 
    addEventListener "keydown", @handleButtonPress

  recordTrial: () =>
    psiTurk.recordTrialData {"trialId":e.state.trialIdGlobal, "blockID":"Practice", "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":@bonus}

  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
        feedbackText = "Correct!\n\n Press the spacebar to continue."
    else 
        feedbackText = "Incorrect! \n\n Press the spacebar to continue."
    r.renderText feedbackText
    addEventListener "keydown", @handleSpacebar

class TestLetterTrial extends PracticeLetterTrial

  recordTrial: () =>
    psiTurk.recordTrialData {"trialId":e.state.testId, "blockID":"Test", "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":@bonus}


  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
        e.state.currentStreak = e.state.currentStreak + 1
        feedbackText = "Correct (Streak: #{e.state.currentStreak})! (#{e.config.nTestAttempts-e.state.testId-1} attempts left)\n\n Press the spacebar to continue."
    else 
        e.state.currentStreak = 0
        feedbackText = "Incorrect! (#{e.config.nTestAttempts-e.state.testId-1} attempts left) \n\n Press the spacebar to continue."
    r.renderText feedbackText
    addEventListener "keydown", @handleSpacebar

class DotsTrial extends Trial
  constructor: (@context, @target, @keys, @cresp, @contextColor="black", @targetColor="black")->
    super(@context, @target, @keys, @cresp, @contextColor, @targetColor)

  run: (state) =>
    @myState = state # hang onto state
    r.clearScreen() 
    @startTime = performance.now() + @myState.config.iti + @myState.config.contextDur
    r.renderDots @context, @contextColor
    setTimeout r.clearScreen, @myState.config.contextDur
    setTimeout (=> r.renderDots @target, @targetColor), @myState.config.iti + @myState.config.contextDur
    setTimeout @enableInput, @myState.config.iti+@myState.config.contextDur
