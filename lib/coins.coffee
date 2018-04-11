boxWidth = 1
boxHeight = 1

edgeWidth = 0.04
coinRadius = 0.9

undoSpeed = 250

neighborCoords = ([x,y]) ->
  [
    [x-1, y]
    [x+1, y]
    [x, y-1]
    [x, y+1]
  ]

class Coin
  constructor: (@x, @y) ->
  coords: ->
    [@x, @y]
  move: ([@x, @y]) ->
  update: (animate = false) ->
    return unless @circle?
    circle = @circle
    circle = circle.animate animate if animate
    circle.center @coords()...

class CoinBox
  constructor: (@svg, @width, @height, @coins) ->
    @coins = [] unless @coins
    if @svg
      @gridGroup = @svg.group()
      .translate -0.5, -0.5
      .addClass 'grid'
      @coinsGroup = @svg.group()
      .addClass 'coins'
    @sizeChange()
    @coinsChange()

  @fromASCII: (svg, ascii) ->
    coins = []
    width = 0
    for row, y in ascii.split '\n'
      width = Math.max width, row.length
      height = y+1
      for char, x in row
        char = char.toLowerCase()
        if char == 'o'
          coins.push new Coin x, y
    new @ svg, width, height, coins

  toASCII: ->
    (for y in [0...@height]
      (for x in [0...@width]
        if @coinAt [x,y]
          'o'
        else
          '-'
      ).join ''
    ).join '\n'

  sizeChange: ->
    return unless @svg?
    @gridGroup.clear()
    for x in [0..@width]
      @gridGroup.line x, 0, x, @height
    for y in [0..@height]
      @gridGroup.line 0, y, @width, y
    @svg.viewbox
      x: -edgeWidth/2 - 0.5  ## -0.5 accounts for translation on @gridGroup
      y: -edgeWidth/2 - 0.5
      width: @width + edgeWidth
      height: @height + edgeWidth

  coinsChange: ->
    return unless @svg?
    @coinsGroup.clear()
    for coin, i in @coins
      coin.circle =
      @coinsGroup.circle coinRadius
      .center coin.coords()...
      #.attr 'data-coin', i

###
  @fromState: (state, svg) ->
    v = new @ svg
    v.loadState state
    v

  loadState: (search = location.search) ->
    if getParameterByName 'p', search
      @sites = for p in getParameterByName('p', search).split ';'
        [x, y] = p.split ','
        x: parseFloat x
        y: parseFloat y
    @siteChange()

###

class @CoinPuzzle extends CoinBox
  constructor: (args...) ->
    super args...
    @moveStack = []
    @listeners = {}

    return unless @svg?
    @svg.addClass 'puzzle'
    @validGroup = @svg.group().back()
    .addClass 'valid'

    @dragPoint = @dragCircle = @dragTouch = null
    @svg.mouseup (e) => @dragstop e
    @svg.on 'mouseleave', (e) => @dragstop e
    @svg.touchend touchend = (e) =>
      return unless @dragTouch?
      e.preventDefault()
      e.stopPropagation()
      for touch in e.changedTouches
        if touch.identifier == @dragTouch
          @dragTouch = null
          @dragstop touch
          break
    @svg.touchcancel touchend
    @svg.mousemove (e) => @dragmove e
    @svg.touchmove (e) =>
      return unless @dragTouch?
      e.preventDefault()
      e.stopPropagation()
      for touch in e.changedTouches
        if touch.identifier == @dragTouch
          @dragmove touch
          break
    #@svg.mouseout (e) =>
    #  console.log 'out'
    #  @dragging = null
    @svg.on 'dragstart', (e) ->
      e.preventDefault()
      e.stopPropagation()
    @svg.on 'selectstart', (e) ->
      e.preventDefault()
      e.stopPropagation()
    #@svg.touchstart (e) ->
    #  e.preventDefault()
    #  e.stopPropagation()

  emit: (event, args...) ->
    for callback in @listeners[event] ? []
      callback args...
  on: (event, callback) ->
    @listeners[event] ?= []
    @listeners[event].push callback
    @  ## allow chaining

  nMoves: ->
    @moveStack.length
  encodeMoves: ->
    ("#{move[0]}_#{move[1]}-#{move[2]}_#{move[3]}" for move in @moveStack)
    .join ' '
  decodeMoves: (encoded) ->
    return unless encoded
    for move in encoded.split ' '
      [before, after] = move.split '-'
      before = (parseInt coord for coord in before.split '_')
      after = (parseInt coord for coord in after.split '_')
      unless before.length == after.length == 2
        console.warn "Invalid move '#{move}'"
        continue
      coin = @coinAt before
      unless coin? and @moveCoin coin, after
        console.warn "Failed to restore move '#{move}'"
        console.warn "(no coin at #{before})" unless coin?
        console.log before, after, coin
        continue
  coinsChange: ->
    super()
    @map = {}
    for coin in @coins
      @map["#{coin.x},#{coin.y}"] = coin
      continue unless @svg?
      do (coin) =>
        coin.circle
        .mousedown (e) =>
          e.preventDefault()
          e.stopPropagation()
          return unless @coinCanMove coin
          @dragstart coin, e
        .touchstart (e) =>
          e.preventDefault()
          e.stopPropagation()
          return unless @coinCanMove coin
          @dragTouch = e.changedTouches[0].identifier
          @dragstart coin, e.changedTouches[0]

  coinAt: ([x,y]) ->
    @map["#{x},#{y}"]

  coinCanMove: (coin) ->
    true

  validMove: (coin, coords) ->
    return false if @coinAt coords
    neighbors = 0
    for neighbor in neighborCoords coords
      neighborCoin = @coinAt neighbor
      if neighborCoin? and neighborCoin != coin
        neighbors += 1
    neighbors >= 2

  ## The following code doesn't work for CoinPuzzleReverse, and with the
  ## "seen" overhead, may not have been much faster for small boards.
  #validTargets: (coin) ->
  #  seen = {}
  #  out = []
  #  for otherCoin in @coins
  #    for possible in neighborCoords otherCoin.coords()
  #      continue if seen["#{possible[0]},#{possible[1]}"]?
  #      if @validMove @dragCoin, possible
  #        seen["#{possible[0]},#{possible[1]}"] = true
  #        out.push possible
  #  out

  validTargets: (coin) ->
    out = [coin.coords()]  ## allow null move back to self
    for x in [0...@width]
      for y in [0...@height]
        coords = [x,y]
        if @validMove coin, coords
          out.push coords
    out

  moveCoin: (coin, coords) ->
    moved = false
    if (coin.x != coords[0] or coin.y != coords[1]) and @validMove coin, coords
      lastMove = @moveStack[@moveStack.length - 1]
      if lastMove? and lastMove[2] == coin.x and lastMove[3] == coin.y
        ## Moving the same coin as previously moved
        if lastMove[0] == coords[0] and lastMove[1] == coords[1]
          ## Manual undo of exact same move
          @moveStack.pop()
        else
          ## Pretend previous move was to here instead
          lastMove[2] = coords[0]
          lastMove[3] = coords[1]
      else
        @moveStack.push [coin.x, coin.y].concat coords
      @map["#{coin.x},#{coin.y}"] = null
      coin.move coords
      @map["#{coin.x},#{coin.y}"] = coin
      @emit 'move'
      moved = true
    coin.update()  ## always do this in case we were draggin the coin
    moved

  undo: (animate = undoSpeed) ->
    return unless @moveStack.length
    move = @moveStack.pop()
    coin = @map["#{move[2]},#{move[3]}"]
    @map["#{move[2]},#{move[3]}"] = null
    coin.move move[0..1]
    coin.update animate
    @map["#{move[0]},#{move[1]}"] = coin
    @emit 'move'

  reset: ->
    while @moveStack.length
      @undo()

  dragstart: (coin, e) ->
    @dragPoint = @svg.point e.clientX, e.clientY
    @dragCoin = coin
    for target in @validTargets coin
      @validGroup.rect 1, 1
      .center target...

  dragcoord: (e, round = false) ->
    point = @svg.point e.clientX, e.clientY
    [x, y] = @dragCoin.coords()
    x += point.x - @dragPoint.x
    y += point.y - @dragPoint.y
    if round
      x = Math.round x
      x = 0 if x < 0
      x = @width-1 if x >= @width
      y = Math.round y
      y = 0 if y < 0
      y = @height-1 if y >= @height
    [x, y]
    
  dragmove: (e) ->
    ## Touch event doesn't have preventDefault/stopPropagation
    e.preventDefault?()
    e.stopPropagation?()
    if @dragPoint?
      @dragCoin.circle.center @dragcoord(e)...

  dragstop: (e) ->
    return unless @dragPoint?
    @validGroup.clear()
    @moveCoin @dragCoin, @dragcoord e, true
    #@saveState()
    @dragPoint = @dragCoin = null
    e.preventDefault()
    e.stopPropagation()

  @checkSolution: (puzzle1, puzzle2, moves) ->
    puzzle1 = CoinPuzzle.fromASCII null, puzzle1
    #puzzle2 = CoinPuzzle.fromASCII null, puzzle2
    for move in moves
      unless coin = puzzle1.coinAt move[0..1]
        return false
      unless puzzle1.moveCoin coin, move[2..3]
        return false
    puzzle1.toASCII() == puzzle2

###
  saveState: ->
    return unless @alone
    siteurl = ("#{site.x},#{site.y}" for site in @sites).join ';'
    history.pushState null, 'voronoi',
      "#{document.location.pathname}?p=#{siteurl}&grid=#{@gridLevel}" +
      if @gridOn then '' else '&off=1'
###

class CoinPuzzleReverse extends CoinPuzzle
  constructor: (args...) ->
    super args...
    @on 'move', => @coinsCheck()

  coinCanMove: (coin) ->
    neighbors = 0
    for neighbor in neighborCoords [coin.x, coin.y]
      if @coinAt neighbor
        neighbors += 1
    neighbors >= 2

  validMove: (coin, coords) ->
    return false if @coinAt coords
    @coinCanMove coin

  coinsChange: ->
    super()
    @coinsCheck()
  coinsCheck: ->
    for coin in @coins
      if @coinCanMove coin
        coin.circle.removeClass 'rigid'
      else
        coin.circle.addClass 'rigid'

## Based on jolly.exe's code from http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
getParameterByName = (name, search = location.search) ->
  name = name.replace /[\[]/g, "\\["
             .replace /[\]]/g, "\\]"
  regex = new RegExp "[\\?&]#{name}=([^&#]*)"
  results = regex.exec search
  return null unless results?
  decodeURIComponent results[1].replace /\+/g, " "

## Based on meouw's answer on http://stackoverflow.com/questions/442404/retrieve-the-position-x-y-of-an-html-element
getOffset = (el) ->
  x = y = 0
  while el and not isNaN(el.offsetLeft) and not isNaN(el.offsetTop)
    x += el.offsetLeft - el.scrollLeft
    y += el.offsetTop - el.scrollTop
    el = el.offsetParent
  x: x
  y: y

## PUZZLE GUI

resize = (ids) ->
  offset = getOffset document.getElementById ids[0]
  height = Math.max 100, window.innerHeight - offset.y
  for id in ids
    document.getElementById(id).style.height = "#{height}px"

puzzleResize = ->
  resize ['startsvg', 'targetsvg']

@puzzleGui = ->
  document.getElementById('undo').addEventListener 'click',
    -> startPuzzle.undo()
  document.getElementById('reverseUndo').addEventListener 'click',
    -> targetPuzzle.undo()
  document.getElementById('reset').addEventListener 'click',
    -> startPuzzle.reset()
  document.getElementById('reverseReset').addEventListener 'click',
    -> targetPuzzle.reset()
  for event in ['input', 'propertychange', 'click']
    ## Changing a letter changes only that side
    document.getElementById('start').addEventListener event, ->
      setStart document.getElementById('start').value
    document.getElementById('target').addEventListener event, ->
      setTarget document.getElementById('target').value
    ## Changing the font resets the entire puzzle
    for checkbox in checkboxes
      document.getElementById(checkbox).addEventListener event, puzzleCheckFont
  window.addEventListener 'popstate', -> puzzleLoadState()
  puzzleLoadState()
  window.addEventListener 'resize', puzzleResize
  puzzleResize()

start = target = null
@startPuzzle = @targetPuzzle = null
lastFont = null
puzzleLoading = false

puzzleLoadState = ->
  puzzleLoading = true
  for checkbox in checkboxes
    document.getElementById(checkbox).checked = getParameterByName checkbox
  for radio in radioButtons
    if (true for key in radio.options when document.getElementById(key).checked).length == 0
      document.getElementById(radio.default).checked = true
  lastFont = getFont()
  setStart getParameterByName('start') ? '/', false
  startPuzzle.decodeMoves getParameterByName 'moves'
  setTarget getParameterByName('target') ? 'A', false
  targetPuzzle.decodeMoves getParameterByName 'rmoves'
  puzzleLoading = false
  puzzleSolveCheck?()

puzzleCheckFont = ->
  font = getFont()
  if lastFont != font
    lastFont = font
    puzzleReset()

puzzleReset = ->
  setStart true
  setTarget true

setStart = (newStart) ->
  return if start == newStart
  start = newStart unless newStart == true
  document.querySelector("select#start option[value='#{start}']").selected = true
  document.getElementById('startsvg').innerHTML = ''
  svg = SVG('startsvg')
  .attr 'preserveAspectRatio', 'xMidYMin'
  @startPuzzle = CoinPuzzle.fromASCII svg, getFont()[start]
  .on 'move', ->
    document.getElementById 'moves'
    .innerHTML = startPuzzle.nMoves()
    puzzleSetState()
  puzzleSetState()

setTarget = (newTarget) ->
  return if target == newTarget
  target = newTarget unless newTarget == true
  document.querySelector("select#target option[value='#{target}']").selected = true
  document.getElementById('targetsvg').innerHTML = ''
  svg = SVG('targetsvg')
  .attr 'preserveAspectRatio', 'xMidYMin'
  @targetPuzzle = CoinPuzzleReverse.fromASCII svg, getFont()[target]
  .on 'move', ->
    document.getElementById 'reverseMoves'
    .innerHTML = targetPuzzle.nMoves()
    puzzleSetState()
  puzzleSetState()

puzzleSetState = ->
  return if puzzleLoading
  params =
    start: document.getElementById('start').value
    target: document.getElementById('target').value
    moves: startPuzzle.encodeMoves()
    rmoves: @targetPuzzle.encodeMoves()
  for checkbox in checkboxes
    params[checkbox] = document.getElementById(checkbox).checked
  setState params
  puzzleSolveCheck?()

@puzzleSolution = ->
  startPuzzle.moveStack[..].concat targetPuzzle.moveStack[..].reverse()

## FONT GUI

radioButtons = [
  options: ['font5x7', 'font5x9']
  default: 'font5x7'
]
checkboxes = ['font5x7', 'font5x9']
checkboxesRebuild = checkboxes

fontLoadState = ->
  for checkbox in checkboxes
    document.getElementById(checkbox).checked = getParameterByName checkbox
  for radio in radioButtons
    if (true for key in radio.options when document.getElementById(key).checked).length == 0
      document.getElementById(radio.default).checked = true
  text = getParameterByName('text') ? 'text'
  document.getElementById('text').value = text
  updateText false

@getFont = ->
  if document.getElementById('font5x7').checked
    window.font5x7
  else
    window.font5x9

old = {}
updateText = (setUrl = true, force = false) ->
  params =
    text: (document.getElementById('text').value
           .replace(/\r\n/g, '\r').replace(/\r/g, '\n'))
  for checkbox in checkboxes
    params[checkbox] = document.getElementById(checkbox).checked
  #classes = []
  #document.getElementById('output').setAttribute 'class', classes.join ' '
  size = document.getElementById('size').value
  document.getElementById('svgSize').sheet.deleteRule 0
  document.getElementById('svgSize').sheet.insertRule(
    "svg { width: #{0.76*size}px; margin: #{size*0.12}px; }", 0)
  checkParams =
    text: params.text
  for checkbox in checkboxesRebuild
    checkParams[checkbox] = params[checkbox]
  return if (true for key of checkParams when checkParams[key] == old[key]).length == (key for key of checkParams).length and not force
  old = checkParams

  font = getFont()
  Box =
    #if params['playable']
      CoinPuzzle
    #else
    #  CoinBox

  charBoxes = {}
  output = document.getElementById 'output'
  output.innerHTML = '' ## clear previous children
  for line in params.text.split '\n'
    output.appendChild outputLine = document.createElement 'p'
    outputLine.setAttribute 'class', 'line'
    outputLine.appendChild outputWord = document.createElement 'span'
    outputWord.setAttribute 'class', 'word'
    for char, c in line
      char = char.toUpperCase()
      if char of font
        letter = font[char]
        svg = SVG outputWord
        box = Box.fromASCII svg, letter
        charBoxes[char] = [] unless charBoxes[char]?
        charBoxes[char].push box
        box.linked = charBoxes[char]
      else if char == ' '
        #space = document.createElement 'span'
        #space.setAttribute 'class', 'space'
        #outputLine.appendChild space
        outputLine.appendChild outputWord = document.createElement 'span'
        outputWord.setAttribute 'class', 'word'
      else
        console.log "Unknown character '#{char}'"

  setState params if setUrl

setState = (params) ->
  encoded =
    for key, value of params
      if value == true
        value = '1'
      else if value == false or value == ''
        continue
      key + '=' + encodeURIComponent(value).replace /%20/g, '+'
  history.replaceState null, 'text',
    "#{document.location.pathname}?#{encoded.join '&'}"

fontResize = ->
  document.getElementById('size').max =
    document.getElementById('size').scrollWidth - 30 - 2
                                              # - circle width - border width

fontGui = ->
  updateTextSoon = (event) ->
    setTimeout updateText, 0
    true
  for event in ['input', 'propertychange', 'keyup']
    document.getElementById('text').addEventListener event, updateTextSoon
  for event in ['input', 'propertychange', 'click']
    for checkbox in checkboxes
      document.getElementById(checkbox).addEventListener event, updateTextSoon
  for event in ['input', 'propertychange', 'click']
    document.getElementById('size').addEventListener event, updateTextSoon
  #document.getElementById('reset').addEventListener 'click', ->
  #  updateText false, true

  window.addEventListener 'popstate', fontLoadState
  fontLoadState()
  window.addEventListener 'resize', fontResize
  fontResize()

## GUI MAIN

window?.onload = ->
  return if Meteor?
  if document.getElementById 'text'
    fontGui()
  else if document.getElementById 'startsvg'
    puzzleGui()

## FONT CHECKING

main = ->
  fonts =
    font5x7: require('./font5x7.js').font5x7
    font5x9: require('./font5x9.js').font5x9
  for name, font of fonts
    console.log name
    for char, ascii of font
      box = CoinBox.fromASCII null, ascii
      console.log "  #{char}: #{box.width}x#{box.height}, #{box.coins.length} coins"

main() if require? and require.main == module
