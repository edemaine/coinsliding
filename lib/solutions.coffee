@Solutions = new Mongo.Collection 'solutions'

if Meteor.isServer
  Meteor.publish 'solutions.puzzle', (family, puzzle) ->
    check family, String
    check puzzle, String
    Solutions.find
      family: family
      puzzle: puzzle
    , fields:
        family: true
        puzzle: true
        name: true
        length: true
        date: true

Meteor.methods
  submitSolution: (solution) ->
    check solution,
      family: String
      puzzle: String
      name: String
      email: String
      moves: [[Number]]
      rmoves: Number
    unless solution.family in ['font5x7', 'font5x9']
      throw new Meteor.Error "Invalid family '#{solution.family}'"
    font = fonts[solution.family]
    unless match = solution.puzzle.match /^([A-Z\/])-([A-Z\/])$/
      throw new Meteor.Error "Invalid puzzle '#{solution.puzzle}'"
    for move in solution.moves
      if move.length != 4
        throw new Meteor.Error "Invalid move '#{move}'"
    unless solution.rmoves >= 0
      throw new Meteor.Error "Invalid rmoves '#{solution.rmoves}'"
    solution.length = solution.moves.length
    solution.date = new Date

    unless CoinPuzzle.checkSolution font[match[1]], font[match[2]], solution.moves
      throw new Meteor.Error "Invalid solution"

    unless Solutions.findOne(
      family: solution.family
      puzzle: solution.puzzle
      name: solution.name
      email: solution.email
      moves: solution.moves
    )
      Solutions.insert solution
      Puzzles.update
        family: solution.family
        puzzle: solution.puzzle
      , $min: bestLength: solution.length
