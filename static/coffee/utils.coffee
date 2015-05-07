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

