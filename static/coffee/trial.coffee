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
    psiTurk.recordTrialData {"trialId":e.state.trialIdGlobal, "blockID":e.state.blockId, "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":@bonus, "dollars":@bonus/e.config.pointsPerDollar}

  handleButtonPress: (event) =>
    if event.keyCode in @keys # it's one of our legal responses
      removeEventListener "keydown", @handleButtonPress
      @rt = performance.now() - @startTime
      @acc = if event.keyCode == @cresp then 1 else 0
      @computeBonus()
      clearTimeout @timeout
      @recordTrial() 
      @showFeedback()

  constructor:(@context, @target, @renderFunc, @contextItem, @targetItem, @keys, @cresp, @contextColor="black", @targetColor="black")-> 

  computeBonus: => 
    @bonus = if @acc is 1 then e.config.correctPoints else -e.config.inaccPenalty
    @bonus = @bonus - @rt * e.config.penaltyPerSecond / 1000 
    e.state.blockBonus = e.state.blockBonus + @bonus
    e.state.globalBonus = e.state.globalBonus + @bonus

  timedOut: =>
    r.clearScreen()
    r.renderText "Timed out! You lose #{e.config.deadline*e.config.penaltyPerSecond+e.config.inaccPenalty} points! \n\n Press spacebar to continue."
    @bonus = -e.config.deadline*e.config.penaltyPerSecond-e.config.inaccPenalty
    e.state.blockBonus = e.state.blockBonus + @bonus
    e.state.globalBonus = e.state.globalBonus + @bonus
    removeEventListener "keydown", @handleButtonPress
    @recordTrial()
    addEventListener "keydown", @handleSpacebar

  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
        r.renderText "Correct! \n Your RT was #{ExtMath.round(@rt, 2)}ms! \n You get #{ExtMath.round(@bonus, 2)} points!"
    else 
        r.renderText "Incorrect! \n Your RT was #{ExtMath.round(@rt,2)}ms! \n You get #{ExtMath.round(@bonus,2)} points!"
    setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 180 ), e.config.spacebarTimeout
    setTimeout (=> addEventListener "keydown", @handleSpacebar), e.config.spacebarTimeout

  enableInput: =>
    addEventListener "keydown", @handleButtonPress
    @timeout = setTimeout @timedOut, e.config.deadline*1000

  run: (state) => 
    r.clearScreen() 
    ri = utils.sampleRetentionInterval(e.config.riMeans, e.config.riSD)
    @startTime = performance.now() + ri + e.config.contextDur
    @renderFunc @contextItem, @contextColor 
    setTimeout r.clearScreen, e.config.contextDur
    setTimeout (=> @renderFunc @targetItem, @targetColor), ri + e.config.contextDur
    setTimeout @enableInput, ri + e.config.contextDur

class PracticeTrial extends Trial
  # remove timeout
  enableInput: => 
    addEventListener "keydown", @handleButtonPress

  computeBonus: => 
    # do nothing... just override so we don't grant bonuses on prax

  recordTrial: () =>
    psiTurk.recordTrialData {"trialId":e.state.trialIdGlobal, "blockID":"Practice", "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":0, "dollars": 0}

  showFeedback: =>
    r.clearScreen()
    if @acc is 1 
      r.renderText "Correct!", "green"
    else 
      r.renderText "Incorrect!", "red"
    setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 180 ), e.config.spacebarTimeout
    setTimeout (=> addEventListener "keydown", @handleSpacebar), e.config.spacebarTimeout

class TestTrial extends PracticeTrial

  recordTrial: () =>
    psiTurk.recordTrialData {"trialId":e.state.testId, "blockID":"Test", "context":@context, "target":@target, "contextItem": @contextItem, "targetItem":@targetItem, "cresp":@cresp, "rt":@rt, "acc":@acc, "bonus":0, "dollars": 0}

  showFeedback: =>
    r.clearScreen()
    if @acc is 1
      e.state.currentStreak = e.state.currentStreak + 1
      r.renderText "Correct (Streak: #{e.state.currentStreak})! (#{e.config.nTestAttempts-e.state.testId-1} attempts left)\n"
    else
      e.state.currentStreak = 0
      r.renderText "Incorrect! (#{e.config.nTestAttempts-e.state.testId-1} attempts left).\n
                    As a reminder, here are the rules: ", "black", 0, -150
      e.renderRules(0, -60)
    
    setTimeout (-> r.renderText "Press the spacebar to continue.", "black", 0, 180 ), e.config.spacebarTimeout
    setTimeout (=> addEventListener "keydown", @handleSpacebar), e.config.spacebarTimeout