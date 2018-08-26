import {solutions} from '../imports/solutions/solutions.js'
import {submitSolution} from '../lib/solutions'

Meteor.startup ->
  for family, familySolutions of solutions
    for puzzle, moves of familySolutions
      #console.log family, puzzle, moves.length
      try
        submitSolution
          family: family
          puzzle: puzzle
          name: "Optimal solution"
          email: "edemaine+coinsliding+optimal@mit.edu"
          moves: moves
          rmoves: 0
        , new Date 'Wed, 16 May 2018 18:53:47'
      catch e
        console.log family, puzzle, 'error:', e.message
