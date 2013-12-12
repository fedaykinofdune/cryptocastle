# This is an abstract class. Extend it with your own in-game prop. In the
# constructor of the subclass, before calling super, define:
#
#	* @layout - 2D array of booleans to describe the tile layout of the prop (default [[]]).
#	* @xPivot - An x-coordinate in @layout around which to apply rotations (default 0).
# 	* @yPivot - A y-coordinate in @layout around which to apply rotations (default 0).

THREE = require('three')

Const = require('./constants')

module.exports = class Prop
	constructor: (spriteTexturePath) ->
		@layout ?= [[]]
		@xPivot ?= 0
		@yPivot ?= 0
		@tile = null
		@spriteHeight = null

		@_setSprite(spriteTexturePath) if spriteTexturePath

		@object

	placeOn: (tile) ->
		return if @tile is tile

		@tile = tile

		@object.position = tile.notch()

		# TODO: Make this work for non 1x1 tile sprites. somehow adjust the
		# inital position of the table in relation to (xPivot, yPivot) and
		# (tile.xGrid, tile.yGrid)
		if @object instanceof THREE.Sprite
			$(@).on('spriteLoaded', =>
				@object.position = @_notchPosition(tile)
			)

		if @object instanceof THREE.Mesh
			@object.position.x += (@yGridSize() - 1) * Const.tileSize / 2
			@object.position.y += @object.geometry.height / 2
			@object.position.z -= (@xGridSize() - 1) * Const.tileSize / 2

	xGridSize: -> @layout[0].length

	yGridSize: -> if @xGridSize() > 0 then @layout.length else 0

	rotateRight: (rotations = 1)->
		return @layout if rotations < 1

		# A rotation to the right is equivalent to a transpose followed by a
		# reflection on the x-axis.
		@_transposeLayout()
		@_flipLayoutX()

		# This is sort of lame but, computationally speaking, we will only make
		# at most 4 recursive calls.
		rotations = (rotations - 1) % 4
		@rotateRight(rotations)

	rotateLeft: (rotations = 1) ->
		return @layout if rotations < 1

		rotationRights = 4 - (rotations % 4)
		@rotateRight(rotationRights)

	_flipLayoutX: ->
		@xPivot = @xGridSize() - 1 - @xPivot

		for y in [0...@yGridSize()]
			for x in [0...Math.floor(@xGridSize() / 2)]
				flippedIndex = @xGridSize() - 1 - x
				temp = @layout[y][x]
				@layout[y][x] = @layout[y][flippedIndex]
				@layout[y][flippedIndex] = temp

		@layout

	_transposeLayout: ->
		temp = @xPivot
		@xPivot = @yPivot
		@yPivot = temp

		newLayout = ([] for x in [0...@xGridSize()])
		for x in [0...@xGridSize()]
			for y in [0...@yGridSize()]
				newLayout[x][y] =  @layout[y][x]

		@layout = newLayout
		@layout

	_setSprite: (spriteTexturePath) ->
		texture = new THREE.ImageUtils.loadTexture(spriteTexturePath, null, (texture) =>
			@object.scale.set(texture.image.width * 2, texture.image.height * 2, 1)
			@spriteHeight = texture.image.height
			$(@).trigger('spriteLoaded')
		)
		material = new THREE.SpriteMaterial(map: texture)
		@object = new THREE.Sprite(material)

	_notchPosition: (tile) ->
		notch = tile.notch()
		notch.y += (@object.geometry?.height or @spriteHeight) / 2
		notch