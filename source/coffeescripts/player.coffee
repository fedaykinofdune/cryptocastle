THREE = require('three')
TWEEN = require('tween')

Prop  = require('./prop')
Tile  = require('./tile')
Const = require('./constants')

module.exports = class Player extends Prop
	constructor: (@room) ->
		@speed = 0.15
		@lastTween = null
		@targetTile = null

		super('/images/player-south.png')

	lift: (prop) ->
		console.log("lifting prop!")

	moveAlong: (path) ->
		return unless path.length > 1

		lastCoordPair = path[path.length - 1]
		@targetTile = @room.tiles[lastCoordPair[0]][lastCoordPair[1]]

		tweens = []

		for coordPair, index in path when index < path.length - 1
			currentTile = @room.tiles[coordPair[0]][coordPair[1]]
			nextCoordPair = path[index + 1]
			nextTile = @room.tiles[nextCoordPair[0]][nextCoordPair[1]]

			firstTween = index is 0
			tween = @_animateTo(currentTile, nextTile, firstTween)
			tweens[index - 1]?.chain(tween)
			tweens.push(tween)

		@lastTween?.stop()
		@lastTween = tweens[0]
		@lastTween.start()

	_animateTo: (startTile, nextTile, firstTween = false) ->
		startPosition = if firstTween then @object.position.clone() else @_notchPosition(startTile)
		nextPosition = @_notchPosition(nextTile)
		time = startPosition.distanceTo(nextPosition) / @speed

		new TWEEN.Tween(startPosition)
			.to(nextPosition, time)
			.onUpdate(=> @object.position.copy(startPosition))
			.onComplete(=> @tile = nextTile)