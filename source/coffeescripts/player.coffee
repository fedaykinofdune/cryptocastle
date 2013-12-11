THREE = require('three')
TWEEN = require('tween')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Player
	constructor: (@room) ->
		@speed = 0.15
		@tile = null
		@lastTween = null
		@targetTile = null

		# Use a temporary player sprite.
		texture = new THREE.ImageUtils.loadTexture('/images/player-south.png')
		material = new THREE.SpriteMaterial(map: texture)
		sprite = new THREE.Sprite(material)
		image = material.map.image
		image.onload = (->
			sprite.scale.set(image.width * 2, image.height * 2, 1)
		)

		@object = sprite 
		@object

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

	placeOn: (tile) ->
		return if @tile is tile

		@tile = tile
		@object.position = tile.notch()

	_animateTo: (startTile, nextTile, firstTween = false) ->
		startPosition = if firstTween then @object.position.clone() else startTile.notch()
		nextPosition = nextTile.notch()
		time = startPosition.distanceTo(nextPosition) / @speed

		new TWEEN.Tween(startPosition)
			.to(nextPosition, time)
			.onUpdate(=> @object.position.copy(startPosition))
			.onComplete(=> @tile = nextTile)