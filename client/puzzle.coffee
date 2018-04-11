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

Template.main.helpers
  family: -> Session.get 'family'
  start: -> Session.get 'start'
  target: -> Session.get 'target'
  moves: -> Session.get 'moves'

  highscore: ->
    (Solutions.findOne
      family: Session.get 'family'
      puzzle: sessionPuzzle()
    , sort: ['length', 'date']
    )?.length or 'NONE'
  highscores: ->
    Solutions.find
      family: Session.get 'family'
      puzzle: sessionPuzzle()
    , sort: ['length', 'date']
  name: ->
    @name or 'Anonymous'
  date: ->
    "#{@date.toLocaleDateString()} at #{@date.toLocaleTimeString()}"

  letters: ['/', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
  sameLetter: (letters) ->
    letters = letters.hash
    letters.letter1 == letters.letter2
  record: (letters) ->
    letters = letters.hash
    (Puzzles.findOne
      family: Session.get 'family'
      puzzle: "#{letters.letter1}-#{letters.letter2}"
    )?.bestLength ? "∞"

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

  'click #showHighscores': (e, t) ->
    document.getElementById('highscores').style.display = 'block'
  'click #hideHighscores': ->
    document.getElementById('highscores').style.display = 'none'

  'click #showPuzzles': (e, t) ->
    document.getElementById('puzzles').style.display = 'block'
  'click #hidePuzzles': ->
    document.getElementById('puzzles').style.display = 'none'

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
