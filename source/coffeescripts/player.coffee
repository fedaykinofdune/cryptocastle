THREE = require('three')
TWEEN = require('tween')
$     = require('jquery')

Prop  = require('./prop')
Tile  = require('./tile')
Const = require('./constants')

module.exports = class Player extends Prop
	object: {}

	_speed: 0.15
	_color: Math.random() * 0xffffff
	_lastTween: null

	constructor: (@room) ->
		@object = @_makeSprite('/images/player-south.png') if window?

		super()

	toJSON: ->
		props =
			speed: @_speed
			color: @_color

		$.extend(super(), props)

	moveAlong: (path) ->
		return unless path.length > 1

		tweens = []

		for coordPair, index in path when index < path.length - 1
			currentTile = @room.tiles[coordPair[0]][coordPair[1]]
			nextCoordPair = path[index + 1]
			nextTile = @room.tiles[nextCoordPair[0]][nextCoordPair[1]]

			firstTween = index is 0
			tween = @_animateTo(currentTile, nextTile, firstTween)
			tweens[index - 1]?.chain(tween)
			tweens.push(tween)

		@_lastTween?.stop()
		@_lastTween = tweens[0]
		@_lastTween.start()

	_animateTo: (startTile, nextTile, firstTween = false) ->
		startPosition = if firstTween then @object.position.clone() else @_notchPosition(startTile)
		nextPosition = @_notchPosition(nextTile)
		time = startPosition.distanceTo(nextPosition) / @_speed

		new TWEEN.Tween(startPosition)
			.to(nextPosition, time)
			.onUpdate(=> @object.position.copy(startPosition))
			.onComplete(=> @tile = nextTile)