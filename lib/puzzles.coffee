@Puzzles = new Mongo.Collection 'puzzles'

if Meteor.isServer
  Meteor.publish 'puzzles.all', ->
    Puzzles.find()

  Meteor.publish 'puzzles.family', (family) ->
    Puzzles.find
      family: family
