@Puzzles = new Mongo.Collection 'puzzles'

if Meteor.isClient
  Meteor.subscribe 'puzzles.all'

if Meteor.isServer
  Meteor.publish 'puzzles.all', ->
    Puzzles.find()
