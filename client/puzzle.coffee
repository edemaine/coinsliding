puzzlesOn = new ReactiveVar

Template.main.onCreated ->
  @autorun ->
    Meteor.subscribe 'solutions.puzzle', Session.get('family'), sessionPuzzle()

Template.main.onRendered ->
  document.getElementById('name').value = Session.get('name') or ''
  document.getElementById('email').value = Session.get('email') or ''
  puzzleGui()

sessionPuzzle = ->
  "#{Session.get 'start'}-#{Session.get 'target'}"
getFamily = ->
  if document.getElementById('font5x7').checked
    'font5x7'
  else
    'font5x9'
getStart = ->
  document.getElementById('start').value
getTarget = ->
  document.getElementById('target').value
getMoves = ->
  startPuzzle.nMoves() + targetPuzzle.nMoves()

infinity = "∞"

Template.registerHelper 'family', -> Session.get 'family'
Template.registerHelper 'start', -> Session.get 'start'
Template.registerHelper 'target', -> Session.get 'target'
Template.registerHelper 'moves', -> Session.get 'moves'

Template.main.helpers
  highscore: ->
    (Solutions.findOne
      family: Session.get 'family'
      puzzle: sessionPuzzle()
    , sort: ['length', 'date']
    )?.length or infinity
  highscores: ->
    Solutions.find
      family: Session.get 'family'
      puzzle: sessionPuzzle()
    , sort: ['length', 'date']
  name: ->
    @name or 'Anonymous'
  date: ->
    "#{@date.toLocaleDateString()} at #{@date.toLocaleTimeString()}"

  puzzlesOn: -> puzzlesOn.get()

Template.main.events
  'click #submit': ->
    Meteor.call 'submitSolution',
      family: getFamily()
      puzzle: "#{getStart()}-#{getTarget()}"
      name: document.getElementById('name').value
      email: document.getElementById('email').value
      moves: puzzleSolution()
      rmoves: targetPuzzle.nMoves()
    , (error, result) ->
      if error
        console.error error
      else
        document.getElementById('win').style.display = 'none'
  'click #noSubmit': ->
    document.getElementById('win').style.display = 'none'

  'click .showHighscores': (e, t) ->
    document.getElementById('highscores').style.display = 'block'
  'click .hideHighscores': ->
    document.getElementById('highscores').style.display = 'none'

  'click .showPuzzles': (e, t) ->
    puzzlesOn.set true
  'click .hidePuzzles': (e, t) ->
    puzzlesOn.set false

  'input #name': ->
    Session.setPersistent 'name', document.getElementById('name').value
  'input #email': ->
    Session.setPersistent 'email', document.getElementById('email').value

@puzzleSolveCheck = ->
  Session.set 'family', getFamily()
  Session.set 'start', getStart()
  Session.set 'target', getTarget()
  Session.set 'moves', getMoves()

  ## Don't check for solving A -> A puzzles
  return if getStart() == getTarget()
  if @startPuzzle?.toASCII() == @targetPuzzle?.toASCII()
    document.getElementById('win').style.display = 'block'
  else
    document.getElementById('win').style.display = 'none'

puzzlesDict = new ReactiveDict

Puzzles.find().observe
  added: added = (puzzle) ->
    return unless puzzle.family and puzzle.puzzle
    puzzlesDict.set "#{puzzle.family}:#{puzzle.puzzle}",
      puzzle.bestLength ? infinity
  changed: added
  removed: (puzzle) ->
    return unless puzzle.family and puzzle.puzzle
    puzzlesDict.set "#{puzzle.family}:#{puzzle.puzzle}", null

Template.puzzlesModal.onCreated ->
  @autorun =>
    @subscribe 'puzzles.family', Session.get 'family'

Template.puzzlesModal.helpers
  letters: ['/', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  sameLetter: (letters) ->
    letters = letters.hash
    letters.letter1 == letters.letter2
  record: (letters) ->
    letters = letters.hash
    puzzlesDict.get "#{Session.get 'family'}:#{letters.letter1}-#{letters.letter2}"
  #puzzlesTable: ->
  #  family = Session.get 'family'
  #  dict = {}
  #  Puzzles.find
  #    family: family
  #  .forEach (puzzle) ->
  #    dict[puzzle.puzzle] = puzzle.bestLength ? infinity
  #  font = getFont()
  #  rows = []
  #  rows.push
  #    for letter2 of font
  #      "<th>#{letter2}</th>"
  #  for letter1 of font
  #    rows.push
  #      for letter2 of font
  #        if letter1 == letter2
  #          '<td><span class="zero">0</span>'
  #        else
  #          """<a href="/?start=#{letter1}&target=#{letter2}&#{family}=1">#{dict["#{letter1}-#{letter2}"]}</a>"""
