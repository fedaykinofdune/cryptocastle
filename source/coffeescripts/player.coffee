THREE = require('three')
TWEEN = require('tween')
$     = require('jquery')

Prop  = require('./prop')
Tile  = require('./tile')
Const = require('./constants')

module.exports = class Player extends Prop
	layout: [[1]]
	object: null
	room: null
	currentPlayer: false

	_speed: 0.15
	_color: null
	_lastTween: null

	constructor: (@room) ->
		@_color ?= Math.random() * 0xffffff
		super()

	render: ->
		@object = @_makeSprite('/images/player-south.png')
		@

	toJSON: ->
		json =
			currentPlayer: @currentPlayer
			_speed: @_speed
			_color: @_color

		$.extend(super(), json)

	moveAlong: (path) ->
		return unless path.length > 1

		@tile = @_coordPair2Tile(path[path.length - 1])
		@_animateAlong(path) if @object

	_coordPair2Tile: (pair) -> @room.tiles[pair[0]][pair[1]]

	_animateAlong: (path) ->
		tweens = []
		for coordPair, index in path when index < path.length - 1
			currentTile = @_coordPair2Tile(coordPair)
			nextTile = @_coordPair2Tile(path[index + 1])

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