// Generated by CoffeeScript 1.9.1
(function() {
  var DotsExperiment, Experiment, ExtMath, LettersExperiment, PracticeTrial, Renderer, TestTrial, Trial, base,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  ExtMath = (function(superClass) {
    extend(ExtMath, superClass);

    function ExtMath() {
      return ExtMath.__super__.constructor.apply(this, arguments);
    }

    ExtMath.round = function(x, precision) {
      var scale;
      if (precision == null) {
        precision = 0;
      }
      scale = Math.pow(10, precision);
      return Math.round(x * scale) / scale;
    };

    return ExtMath;

  })(Math);

  if ((base = Array.prototype).shuffle == null) {
    base.shuffle = function() {
      var i, j, k, ref, ref1;
      if (this.length > 1) {
        for (i = k = ref = this.length - 1; ref <= 1 ? k <= 1 : k >= 1; i = ref <= 1 ? ++k : --k) {
          j = Math.floor(Math.random() * (i + 1));
          ref1 = [this[j], this[i]], this[i] = ref1[0], this[j] = ref1[1];
        }
      }
      return this;
    };
  }

  Renderer = (function() {
    Renderer.prototype.drawingContext = null;

    function Renderer(config) {
      this.config = config;
      this.clearScreen = bind(this.clearScreen, this);
    }

    Renderer.prototype.createDrawingContext = function() {
      this.canvas = document.createElement('canvas');
      document.body.appendChild(this.canvas);
      this.canvas.style.display = "block";
      this.canvas.style.margin = "0 auto";
      this.canvas.style.padding = "0";
      this.canvas.width = 1024;
      this.canvas.height = 768;
      this.drawingContext = this.canvas.getContext('2d');
      this.drawingContext.font = this.config.instructionFontSize + "px " + this.config.fontFamily;
      return this.drawingContext.textAlign = "center";
    };

    Renderer.prototype.renderText = function(text, color, shiftx, shifty, size) {
      if (color == null) {
        color = "black";
      }
      if (shiftx == null) {
        shiftx = 0;
      }
      if (shifty == null) {
        shifty = 0;
      }
      if (size == null) {
        size = e.config.instructionFontSize;
      }
      this.drawingContext.font = size + "px " + this.config.fontFamily + " ";
      return this.fillTextMultiLine(this.drawingContext, text, this.canvas.width / 2 + shiftx, this.canvas.height / 2 + shifty, color);
    };

    Renderer.prototype.fillTextMultiLine = function(ctx, text, x, y, color) {
      var k, len, line, lineHeight, lines, results;
      lineHeight = ctx.measureText("M").width * 1.4;
      lines = text.split("\n");
      ctx.fillStyle = color;
      results = [];
      for (k = 0, len = lines.length; k < len; k++) {
        line = lines[k];
        ctx.fillText(line, x, y);
        results.push(y += lineHeight);
      }
      return results;
    };

    Renderer.prototype.renderCircle = function(x, y, radius, fill, color) {
      if (fill == null) {
        fill = true;
      }
      if (color == null) {
        color = "black";
      }
      this.drawingContext.strokeStyle = 'color';
      this.drawingContext.beginPath();
      this.drawingContext.arc(x, y, radius, 0, 2 * Math.PI, false);
      this.drawingContext.fillStyle = 'white';
      if (fill) {
        this.drawingContext.fillStyle = color;
        this.drawingContext.fill();
      }
      this.drawingContext.lineWidth = 1;
      return this.drawingContext.stroke();
    };

    Renderer.prototype.renderDots = function(stim, color, shiftX, shiftY, radius, sep) {
      var centerx, centery, i, k, len, offset, offsets, results;
      if (color == null) {
        color = "black";
      }
      if (shiftX == null) {
        shiftX = 0;
      }
      if (shiftY == null) {
        shiftY = 0;
      }
      if (radius == null) {
        radius = 10;
      }
      if (sep == null) {
        sep = 20;
      }
      centerx = this.canvas.width / 2 + shiftX;
      centery = this.canvas.height / 2 + shiftY - sep;
      offsets = [[-1, -1], [1, -1], [-1, 1], [1, 1]];
      results = [];
      for (i = k = 0, len = offsets.length; k < len; i = ++k) {
        offset = offsets[i];
        results.push(this.renderCircle(centerx + offset[0] * sep, centery + offset[1] * sep, radius, stim[i], color));
      }
      return results;
    };

    Renderer.prototype.clearScreen = function() {
      return this.drawingContext.clearRect(0, 0, this.canvas.width, this.canvas.height);
    };

    return Renderer;

  })();

  Trial = (function() {
    Trial.prototype.startTime = null;

    Trial.prototype.rt = null;

    Trial.prototype.acc = null;

    Trial.prototype.bonus = null;

    Trial.prototype.next = null;

    Trial.prototype.timeout = null;

    Trial.prototype.myState = null;

    Trial.prototype.handleSpacebar = function(event) {
      if (event.keyCode === 32) {
        removeEventListener("keydown", this.handleSpacebar);
        return e.doNext();
      }
    };

    Trial.prototype.recordTrial = function() {
      return psiTurk.recordTrialData({
        "trialId": e.state.trialIdGlobal,
        "blockID": e.state.blockId,
        "context": this.context,
        "target": this.target,
        "contextItem": this.contextItem,
        "targetItem": this.targetItem,
        "cresp": this.cresp,
        "rt": this.rt,
        "acc": this.acc,
        "bonus": this.bonus
      });
    };

    Trial.prototype.handleButtonPress = function(event) {
      var ref;
      if (ref = event.keyCode, indexOf.call(this.keys, ref) >= 0) {
        removeEventListener("keydown", this.handleButtonPress);
        this.rt = performance.now() - this.startTime;
        this.acc = event.keyCode === this.cresp ? 1 : 0;
        this.computeBonus();
        clearTimeout(this.timeout);
        this.recordTrial();
        return this.showFeedback();
      }
    };

    function Trial(context, target, renderFunc, contextItem, targetItem, keys, cresp, contextColor, targetColor) {
      this.context = context;
      this.target = target;
      this.renderFunc = renderFunc;
      this.contextItem = contextItem;
      this.targetItem = targetItem;
      this.keys = keys;
      this.cresp = cresp;
      this.contextColor = contextColor != null ? contextColor : "black";
      this.targetColor = targetColor != null ? targetColor : "black";
      this.run = bind(this.run, this);
      this.enableInput = bind(this.enableInput, this);
      this.showFeedback = bind(this.showFeedback, this);
      this.timedOut = bind(this.timedOut, this);
      this.computeBonus = bind(this.computeBonus, this);
      this.handleButtonPress = bind(this.handleButtonPress, this);
      this.recordTrial = bind(this.recordTrial, this);
      this.handleSpacebar = bind(this.handleSpacebar, this);
    }

    Trial.prototype.computeBonus = function() {
      this.bonus = this.acc === 1 ? e.config.correctPoints : -e.config.inaccPenalty;
      this.bonus = this.bonus - this.rt * e.config.penaltyPerSecond / 1000;
      e.state.blockBonus = e.state.blockBonus + this.bonus;
      return e.state.globalBonus = e.state.globalBonus + this.bonus;
    };

    Trial.prototype.timedOut = function() {
      r.clearScreen();
      r.renderText("Timed out! Press spacebar to continue.");
      removeEventListener("keydown", this.handleButtonPress);
      this.recordTrial();
      return addEventListener("keydown", this.handleSpacebar);
    };

    Trial.prototype.showFeedback = function() {
      r.clearScreen();
      if (this.acc === 1) {
        r.renderText("Correct! \n Your RT was " + (ExtMath.round(this.rt, 2)) + "ms! \n You get " + (ExtMath.round(this.bonus, 2)) + " points! \n\n Press the spacebar to continue.");
      } else {
        r.renderText("Incorrect! \n Your RT was " + (ExtMath.round(this.rt, 2)) + "ms! \n You get " + (ExtMath.round(this.bonus, 2)) + " points! \n\n Press the spacebar to continue.");
      }
      return addEventListener("keydown", this.handleSpacebar);
    };

    Trial.prototype.enableInput = function() {
      addEventListener("keydown", this.handleButtonPress);
      return this.timeout = setTimeout(this.timedOut, e.config.deadline * 1000);
    };

    Trial.prototype.run = function(state) {
      r.clearScreen();
      this.startTime = performance.now() + e.config.retentionInterval + e.config.contextDur;
      this.renderFunc(this.contextItem, this.contextColor);
      setTimeout(r.clearScreen, e.config.contextDur);
      setTimeout(((function(_this) {
        return function() {
          return _this.renderFunc(_this.targetItem, _this.targetColor);
        };
      })(this)), e.config.retentionInterval + e.config.contextDur);
      return setTimeout(this.enableInput, e.config.retentionInterval + e.config.contextDur);
    };

    return Trial;

  })();

  PracticeTrial = (function(superClass) {
    extend(PracticeTrial, superClass);

    function PracticeTrial() {
      this.showFeedback = bind(this.showFeedback, this);
      this.recordTrial = bind(this.recordTrial, this);
      this.computeBonus = bind(this.computeBonus, this);
      this.enableInput = bind(this.enableInput, this);
      return PracticeTrial.__super__.constructor.apply(this, arguments);
    }

    PracticeTrial.prototype.enableInput = function() {
      return addEventListener("keydown", this.handleButtonPress);
    };

    PracticeTrial.prototype.computeBonus = function() {};

    PracticeTrial.prototype.recordTrial = function() {
      return psiTurk.recordTrialData({
        "trialId": e.state.trialIdGlobal,
        "blockID": "Practice",
        "context": this.context,
        "target": this.target,
        "contextItem": this.contextItem,
        "targetItem": this.targetItem,
        "cresp": this.cresp,
        "rt": this.rt,
        "acc": this.acc,
        "bonus": this.bonus
      });
    };

    PracticeTrial.prototype.showFeedback = function() {
      r.clearScreen();
      if (this.acc === 1) {
        r.renderText("Correct!\n\n Press the spacebar to continue.", "green");
      } else {
        r.renderText("Incorrect! \n\n Press the spacebar to continue.", "red");
      }
      return addEventListener("keydown", this.handleSpacebar);
    };

    return PracticeTrial;

  })(Trial);

  TestTrial = (function(superClass) {
    extend(TestTrial, superClass);

    function TestTrial() {
      this.showFeedback = bind(this.showFeedback, this);
      this.recordTrial = bind(this.recordTrial, this);
      return TestTrial.__super__.constructor.apply(this, arguments);
    }

    TestTrial.prototype.recordTrial = function() {
      return psiTurk.recordTrialData({
        "trialId": e.state.testId,
        "blockID": "Test",
        "context": this.context,
        "target": this.target,
        "contextItem": this.contextItem,
        "targetItem": this.targetItem,
        "cresp": this.cresp,
        "rt": this.rt,
        "acc": this.acc,
        "bonus": this.bonus
      });
    };

    TestTrial.prototype.showFeedback = function() {
      r.clearScreen();
      if (this.acc === 1) {
        e.state.currentStreak = e.state.currentStreak + 1;
        r.renderText("Correct (Streak: " + e.state.currentStreak + ")! (" + (e.config.nTestAttempts - e.state.testId - 1) + " attempts left)\n");
      } else {
        e.state.currentStreak = 0;
        r.renderText("Incorrect! (" + (e.config.nTestAttempts - e.state.testId - 1) + " attempts left).\n As a reminder, here are the rules: ", "black", 0, -150);
        e.renderRules(0, -60);
      }
      setTimeout((function() {
        return r.renderText("Press the spacebar to continue.", "black", 0, 180);
      }), e.config.spacebarTimeout);
      return setTimeout(((function(_this) {
        return function() {
          return addEventListener("keydown", _this.handleSpacebar);
        };
      })(this)), e.config.spacebarTimeout);
    };

    return TestTrial;

  })(PracticeTrial);

  Experiment = (function() {
    Experiment.prototype.state = null;

    Experiment.prototype.config = null;

    function Experiment(config) {
      this.config = config;
      this.handleSpacebar = bind(this.handleSpacebar, this);
      this.state = {
        blockId: 0,
        trialIdGlobal: 0,
        aPraxId: 0,
        bPraxId: 0,
        testId: 0,
        blockBonus: 0,
        globalBonus: 0,
        currentStreak: 0,
        phase: "initialInstructions"
      };
      this.config.nTrials = this.config.blockSize * this.config.nBlocks;
      this.config.payoffId = this.createInitialState;
      r.createDrawingContext();
      this.createTrialTypes();
      this.shuffleTrials();
    }

    Experiment.prototype.shuffleTrials = function() {
      var i, k, l, len, ref, tc, td, trialCounts;
      trialCounts = (function() {
        var k, len, ref, results;
        ref = this.config.trialDist;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          td = ref[k];
          results.push(td * this.config.nTrials);
        }
        return results;
      }).call(this);
      this.trialOrder = [];
      for (i = k = 0, len = trialCounts.length; k < len; i = ++k) {
        tc = trialCounts[i];
        for (l = 1, ref = tc; 1 <= ref ? l <= ref : l >= ref; 1 <= ref ? l++ : l--) {
          this.trialOrder = this.trialOrder.concat(i);
        }
      }
      return this.trialOrder.shuffle();
    };

    Experiment.prototype.handleSpacebar = function(event) {
      if (event.keyCode === 32) {
        removeEventListener("keydown", this.handleSpacebar);
        this.state.instructionSlide = this.state.instructionSlide + 1;
        return this.showInstructions();
      }
    };

    Experiment.prototype.setState = function(state) {
      return this.state = state;
    };

    Experiment.prototype.run = function() {
      return this.doNext();
    };

    Experiment.prototype.doNext = function() {
      r.clearScreen();
      switch (this.state.phase) {
        case "initialInstructions":
          this.state.instructionSlide = 0;
          return this.showInstructions();
        case "APractice":
          this.state.aPraxId = this.state.aPraxId + 1;
          this.state.trialIdGlobal = this.state.trialIdGlobal + 1;
          if (this.state.aPraxId < this.config.nPraxTrials) {
            return setTimeout(((function(_this) {
              return function() {
                return _this.praxTrialTypes[_this.aPrax[_this.state.aPraxId]].run();
              };
            })(this)), this.config.iti);
          } else {
            this.state.instructionSlide = 4;
            return this.showInstructions();
          }
          break;
        case "BPractice":
          this.state.bPraxId = this.state.bPraxId + 1;
          this.state.trialIdGlobal = this.state.trialIdGlobal + 1;
          if (this.state.bPraxId < this.config.nPraxTrials) {
            return setTimeout(((function(_this) {
              return function() {
                return _this.praxTrialTypes[_this.bPrax[_this.state.bPraxId]].run();
              };
            })(this)), this.config.iti);
          } else {
            this.state.instructionSlide = 6;
            return this.showInstructions();
          }
          break;
        case "test":
          this.state.testId = this.state.testId + 1;
          this.state.trialIdGlobal = this.state.trialIdGlobal + 1;
          if (this.state.currentStreak === this.config.testStreakToPass) {
            psiTurk.recordUnstructuredData("trialsToLearn", this.state.testId);
            this.state.instructionSlide = 8;
            return this.showInstructions();
          } else if (this.state.testId < this.config.nTestAttempts) {
            return setTimeout(((function(_this) {
              return function() {
                return _this.testTrialTypes[_this.testTrialOrder[_this.state.testId]].run();
              };
            })(this)), this.config.iti);
          } else {
            return this.endExperimentFail();
          }
          break;
        case "experiment":
          this.state.trialIdGlobal = this.state.trialIdGlobal + 1;
          if (this.state.trialIdGlobal === this.config.nTrials) {
            return this.endExperimentTrials();
          } else if ((this.state.globalBonus / this.config.pointsPerDollar) >= this.config.maxBonus) {
            return this.endExperimentMoney();
          } else if ((modulo(this.state.trialIdGlobal, this.config.blockSize)) === 0) {
            this.state.blockId = this.state.blockId + 1;
            return this.blockFeedback();
          } else {
            return setTimeout(((function(_this) {
              return function() {
                return _this.trialTypes[_this.trialOrder[_this.state.trialIdGlobal]].run();
              };
            })(this)), this.config.iti);
          }
      }
    };

    Experiment.prototype.endExperiment = function() {
      psiTurk.saveData();
      return psiTurk.completeHIT();
    };

    Experiment.prototype.endExperimentMoney = function() {
      r.clearScreen();
      r.renderText("Congratulations! You have achieved the maximum possible bonus.\n You will be paid $" + (this.config.minPayment + this.config.maxBonus) + " for your time.\n If you have any questions, email " + this.config.experimenterEmail + ". Please press any key to continue.");
      psiTurk.recordUnstructuredData('expEndReason', 'maxMoney');
      return addEventListener("keyDown", this.endExperiment);
    };

    Experiment.prototype.endExperimentTrials = function() {
      var cashBonus;
      r.clearScreen();
      cashBonus = this.state.globalBonus < 0 ? 0 : ExtMath.round(this.state.globalBonus / this.config.pointsPerDollar, 2);
      r.renderText("Thank you! This concludes the experiment.\n Based on achieving " + (ExtMath.round(this.state.globalBonus, 2)) + " points,\n you will be paid $" + cashBonus + " for your time.\n If you have any questions, email " + this.config.experimenterEmail + ". Please press any key to continue.");
      psiTurk.recordUnstructuredData('expEndReason', 'trials');
      return addEventListener("keyDown", this.endExperiment);
    };

    Experiment.prototype.endExperimentFail = function() {
      r.clearScreen();
      r.renderText("Unfortunately, you were unable to get " + this.config.testStreakToPass + " correct in a row.\n This means that you cannot continue with the experiment.\n You will receive $" + this.config.minPayment + " for your time.\n If you have any questions, email " + this.config.experimenterEmail + ". Please press any key to continue.");
      return addEventListener("keyDown", this.endExperiment);
    };

    Experiment.prototype.startExperiment = function() {
      this.state.phase = "experiment";
      psiTurk.finishInstructions();
      this.state.trialIdGlobal = 0;
      return this.trialTypes[this.trialOrder[0]].run();
    };

    Experiment.prototype.blockFeedback = function() {
      var feedbackText;
      r.clearScreen();
      feedbackText = "Done with this block! \n Your bonus for this block was " + (ExtMath.round(this.state.blockBonus, 2)) + "!\n Your bonus for the experiment so far is " + (ExtMath.round(this.state.globalBonus, 2)) + "!\n Please take a short break.\n The experiment will continue in " + this.config.blockRestDur + " seconds.";
      r.renderText(feedbackText);
      this.state.blockBonus = 0;
      setTimeout(((function(_this) {
        return function() {
          return _this.trialTypes[_this.trialOrder[_this.state.trialIdGlobal]].run(_this);
        };
      })(this)), this.config.blockRestDur * 1000);
      return psiTurk.saveData();
    };

    Experiment.prototype.showInstructions = function() {
      switch (this.state.instructionSlide) {
        case 0:
          r.renderText("Welcome to the experiment!\n In this experiment, you will make responses to pairs of stimuli.\n The two stimuli in each pair will be separated by a blank screen.\n There will be one correct response for each pair of stimuli.\n\n");
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 200);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 1:
          r.clearScreen();
          r.renderText("First, you will learn the rules mapping stimuli to responses.\n Then, we will test that you learned the mappings.\n If you fail, the HIT will end and you will earn the minimum payment ($" + this.config.minPayment + ").\n If you succeed, you will compete for an additional bonus of up to $" + this.config.maxBonus + ".\n You response keys will be \"F\" (LEFT) and \"J\" (RIGHT). \n You should put your left index finger on \"F\" and right index finger on \"J\" now. \n\n");
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 300);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 2:
          r.clearScreen();
          r.renderText("Here is the first rule:\n followed by      -->  hit the LEFT key\n followed by      -->  hit the RIGHT key\n\n Now you will get a chance to practice.");
          this.renderStimInstruct(this.stimuli[0], "blue", -260, 35);
          this.renderStimInstruct(this.stimuli[1], "green", -60, 35);
          this.renderStimInstruct(this.stimuli[0], "blue", -260, 75);
          this.renderStimInstruct(this.stimuli[2], "green", -60, 75);
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 200);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 3:
          this.state.phase = "APractice";
          return this.praxTrialTypes[this.aPrax[0]].run();
        case 4:
          r.clearScreen();
          r.renderText("Here is the second rule:\n followed by      -->  hit the LEFT key\n followed by      -->  hit the RIGHT key\n\n Now you will get a chance to practice.");
          this.renderStimInstruct(this.stimuli[3], "blue", -260, 35);
          this.renderStimInstruct(this.stimuli[2], "green", -60, 35);
          this.renderStimInstruct(this.stimuli[3], "blue", -260, 75);
          this.renderStimInstruct(this.stimuli[1], "green", -60, 75);
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 200);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 5:
          this.state.phase = "BPractice";
          return this.praxTrialTypes[this.bPrax[0]].run();
        case 6:
          r.clearScreen();
          r.renderText("Now, we will test that you have learned the rules.\n You will see a sequence of trials. Your goal is to get " + this.config.testStreakToPass + " correct in a row.\n You will have " + this.config.nTestAttempts + " trials total. If you get " + this.config.testStreakToPass + " correct in a row, you can compete\n for a bonus of up to $" + this.config.maxBonus + ". If you get to " + this.config.nTestAttempts + " without getting " + this.config.testStreakToPass + " in a row, \n the HIT will end and you will get the minimum payment ($" + this.config.minPayment + ").\n\n As a reminder, here are the rules: \n", "black", 0, -200);
          this.renderRules(0, 60);
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 230);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 7:
          r.clearScreen();
          this.state.phase = "test";
          return this.testTrialTypes[this.testTrialOrder[0]].run();
        case 8:
          r.clearScreen();
          r.renderText("Congratulations! You have learned the rules.\n You will now see up to " + this.config.nTrials + " more trials in blocks of " + this.config.blockSize + ".\n You will get " + this.config.correctPoints + " points for a correct repsonse.\n You will lose " + this.config.inaccPenalty + " points for a wrong response.\n You will lose " + this.config.penaltyPerSecond + " points per second you take to respond. \n If you do not respond in " + this.config.deadline + " seconds, you will lose " + (this.config.deadline * this.config.penaltyPerSecond + this.config.inaccPenalty) + " points.\n That is, it is better to be right than wrong, and better to be fast than slow. \n How much better is for you to figure out: try to get as many points as you can! \n You will receive $1 for each " + this.config.pointsPerDollar + " points.\n Your points can be negative but you cannot lose your $" + this.config.minPayment + " baseline.\n The HIT will end when you have done " + this.config.nTrials + " trials total or earned " + (this.config.maxBonus * this.config.pointsPerDollar) + " points.\n\n", "black", 0, -200);
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 260);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 9:
          r.clearScreen();
          r.renderText("As a reminder, here are the rules:", "black", 0, -200);
          this.renderRules(0, -150);
          setTimeout((function() {
            return r.renderText("Press the spacebar to continue.", "black", 0, 260);
          }), this.config.spacebarTimeout);
          return setTimeout(((function(_this) {
            return function() {
              return addEventListener("keydown", _this.handleSpacebar);
            };
          })(this)), this.config.spacebarTimeout);
        case 10:
          r.clearScreen();
          return this.startExperiment();
      }
    };

    Experiment.prototype.renderRules = function(xoffset, yoffset) {
      if (xoffset == null) {
        xoffset = 0;
      }
      if (yoffset == null) {
        yoffset = 0;
      }
      r.renderText("followed by      -->  hit the LEFT key\n followed by      -->  hit the LEFT key\n followed by      -->  hit the RIGHT key\n followed by      -->  hit the RIGHT key", "black", xoffset, yoffset);
      this.renderStimInstruct(e.stimuli[0], "blue", -280 + xoffset, 105 + yoffset);
      this.renderStimInstruct(e.stimuli[2], "green", -60 + xoffset, 105 + yoffset);
      this.renderStimInstruct(e.stimuli[0], "blue", -280 + xoffset, 35 + yoffset);
      this.renderStimInstruct(e.stimuli[1], "green", -60 + xoffset, 35 + yoffset);
      this.renderStimInstruct(e.stimuli[3], "blue", -280 + xoffset, 70 + yoffset);
      this.renderStimInstruct(e.stimuli[1], "green", -60 + xoffset, 70 + yoffset);
      this.renderStimInstruct(e.stimuli[3], "blue", -280 + xoffset, 0 + yoffset);
      return this.renderStimInstruct(e.stimuli[2], "green", -60 + xoffset, 0 + yoffset);
    };

    Experiment.prototype.createTrialTypes = function() {
      var i, k, l, len, len1, len2, m, n, o, p, pc, praxCounts, ref, ref1, ref2, tc, testCounts;
      this.stimuli.shuffle();
      this.trialTypes = [new Trial("A", "X", this.renderStimTrial, this.stimuli[0], this.stimuli[1], [70, 74], 70, "blue", "green"), new Trial("A", "Y", this.renderStimTrial, this.stimuli[0], this.stimuli[2], [70, 74], 74, "blue", "green"), new Trial("B", "X", this.renderStimTrial, this.stimuli[3], this.stimuli[1], [70, 74], 74, "blue", "green"), new Trial("B", "Y", this.renderStimTrial, this.stimuli[3], this.stimuli[2], [70, 74], 70, "blue", "green")];
      this.praxTrialTypes = [new PracticeTrial("A", "X", this.renderStimTrial, this.stimuli[0], this.stimuli[1], [70, 74], 70, "blue", "green"), new PracticeTrial("A", "Y", this.renderStimTrial, this.stimuli[0], this.stimuli[2], [70, 74], 74, "blue", "green"), new PracticeTrial("B", "X", this.renderStimTrial, this.stimuli[3], this.stimuli[1], [70, 74], 74, "blue", "green"), new PracticeTrial("B", "Y", this.renderStimTrial, this.stimuli[3], this.stimuli[2], [70, 74], 70, "blue", "green")];
      this.testTrialTypes = [new TestTrial("A", "X", this.renderStimTrial, this.stimuli[0], this.stimuli[1], [70, 74], 70, "blue", "green"), new TestTrial("A", "Y", this.renderStimTrial, this.stimuli[0], this.stimuli[2], [70, 74], 74, "blue", "green"), new TestTrial("B", "X", this.renderStimTrial, this.stimuli[3], this.stimuli[1], [70, 74], 74, "blue", "green"), new TestTrial("B", "Y", this.renderStimTrial, this.stimuli[3], this.stimuli[2], [70, 74], 70, "blue", "green")];
      praxCounts = (function() {
        var k, results;
        results = [];
        for (i = k = 1; k <= 2; i = ++k) {
          results.push(this.config.nPraxTrials / 2);
        }
        return results;
      }).call(this);
      this.aPrax = [];
      this.bPrax = [];
      for (i = k = 0, len = praxCounts.length; k < len; i = ++k) {
        pc = praxCounts[i];
        for (l = 1, ref = pc; 1 <= ref ? l <= ref : l >= ref; 1 <= ref ? l++ : l--) {
          this.aPrax = this.aPrax.concat(i);
        }
      }
      for (i = m = 0, len1 = praxCounts.length; m < len1; i = ++m) {
        pc = praxCounts[i];
        for (n = 1, ref1 = pc; 1 <= ref1 ? n <= ref1 : n >= ref1; 1 <= ref1 ? n++ : n--) {
          this.bPrax = this.bPrax.concat(i + 2);
        }
      }
      this.aPrax.shuffle();
      this.bPrax.shuffle();
      testCounts = (function() {
        var o, results;
        results = [];
        for (i = o = 1; o <= 4; i = ++o) {
          results.push(this.config.nTestAttempts / 4);
        }
        return results;
      }).call(this);
      this.testTrialOrder = [];
      for (i = o = 0, len2 = testCounts.length; o < len2; i = ++o) {
        tc = testCounts[i];
        for (p = 1, ref2 = tc; 1 <= ref2 ? p <= ref2 : p >= ref2; 1 <= ref2 ? p++ : p--) {
          this.testTrialOrder = this.testTrialOrder.concat(i);
        }
      }
      return this.testTrialOrder.shuffle();
    };

    return Experiment;

  })();

  LettersExperiment = (function(superClass) {
    extend(LettersExperiment, superClass);

    function LettersExperiment() {
      this.renderStimTrial = bind(this.renderStimTrial, this);
      return LettersExperiment.__super__.constructor.apply(this, arguments);
    }

    LettersExperiment.prototype.stimuli = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

    LettersExperiment.prototype.renderStimInstruct = function(stim, colour, xoffset, yoffset) {
      if (colour == null) {
        colour = "black";
      }
      if (xoffset == null) {
        xoffset = 0;
      }
      if (yoffset == null) {
        yoffset = 0;
      }
      return r.renderText(stim, colour, xoffset, yoffset);
    };

    LettersExperiment.prototype.renderStimTrial = function(stim, colour, xoffset, yoffset) {
      if (colour == null) {
        colour = "black";
      }
      if (xoffset == null) {
        xoffset = 0;
      }
      if (yoffset == null) {
        yoffset = 0;
      }
      return r.renderText(stim, colour, xoffset, yoffset, e.config.taskFontSize);
    };

    return LettersExperiment;

  })(Experiment);

  DotsExperiment = (function(superClass) {
    extend(DotsExperiment, superClass);

    function DotsExperiment() {
      return DotsExperiment.__super__.constructor.apply(this, arguments);
    }

    DotsExperiment.prototype.stimuli = [[0, 0, 1, 1], [0, 1, 0, 1], [0, 1, 1, 0], [1, 0, 0, 1], [1, 0, 1, 0], [1, 1, 0, 0]];

    DotsExperiment.prototype.renderStimInstruct = function(stim, colour, xoffset, yoffset) {
      if (colour == null) {
        colour = "black";
      }
      if (xoffset == null) {
        xoffset = 0;
      }
      if (yoffset == null) {
        yoffset = 0;
      }
      return r.renderDots(stim, colour, xoffset, yoffset, 5, 7);
    };

    DotsExperiment.prototype.renderStimTrial = function(stim, colour, xoffset, yoffset) {
      if (colour == null) {
        colour = "black";
      }
      if (xoffset == null) {
        xoffset = 0;
      }
      if (yoffset == null) {
        yoffset = 0;
      }
      return r.renderDots(stim, colour, xoffset, yoffset, 15, 20);
    };

    return DotsExperiment;

  })(Experiment);

  window.Experiment = DotsExperiment;

  window.Renderer = Renderer;

}).call(this);
