# This is an abstract class. Extend it with your own in-game prop. In the
# constructor of the subclass, before calling super, define:
#
#	* @layout - 2D array of booleans to describe the tile layout of the prop (default [[]]).
#	* @xPivot - An x-coordinate in @layout around which to apply rotations (default 0).
# 	* @yPivot - A y-coordinate in @layout around which to apply rotations (default 0).

THREE = require('three')
_     = require('underscore')

Const = require('./constants')

module.exports = class Prop
	constructor: (spriteTexturePath) ->
		# TODO: Layout is actually not needed. All we need is width and height.
		# TODO: @xPivot and @yPivot are actually not needed. @tile can be used
		# as an implicit market for the pivot point.
		@layout ?= [[]]
		@xPivot ?= 0
		@yPivot ?= 0
		@tile = null
		@spriteHeight = null

		@_setSprite(spriteTexturePath) if spriteTexturePath

		@object.name = 'prop'
		@object

	# Uses the main @tile and (@xPivot, @yPivot) coordinates to visit each tile
	# the prop occupies.
	eachTile: (callback) ->
		return unless @tile
		for x in [0...@xGridSize()]
			for y in [0...@yGridSize()]
				continue unless @layout[y][x]
				xIndex = x + @tile.xGrid - @xPivot
				yIndex = y + @tile.yGrid - @yPivot
				callback(xIndex, yIndex)

	# Performs a deep copy of Prop, meaning its mesh and @layout variable get
	# copied as well. 
	# NOTE: This function will not extend to new complex attributes added to the
	# class down the road. Primitives, nested arrays and objects are fine but
	# stuff like THREE.Mesh will have to be manually cloned.
	clone: ->
		copy = $.extend(true, {}, @)
		copy.object = @object.clone()
		copy.object.material = @object.material.clone()
		copy

	placeOn: (@tile) ->
		@object.position = @tile.notch()

		# TODO: Make this work for non 1x1 tile sprites. somehow adjust the
		# inital position of the table in relation to (xPivot, yPivot) and
		# (tile.xGrid, tile.yGrid)
		if @object instanceof THREE.Sprite
			$(@).on('spriteLoaded', =>
				@object.position = @_notchPosition(@tile)
			)

		if @object instanceof THREE.Mesh
			@object.position.x += (@yGridSize() - 1) * Const.tileSize / 2 - (@yPivot * Const.tileSize)
			@object.position.y += @object.geometry.height / 2
			@object.position.z -= (@xGridSize() - 1) * Const.tileSize / 2 - (@xPivot * Const.tileSize)

	xGridSize: -> @layout[0].length

	yGridSize: -> if @xGridSize() > 0 then @layout.length else 0

	rotateRight: (rotations = 1)->
		return @placeOn(@tile) if rotations < 1

		# A rotation to the right is equivalent to a transpose followed by a
		# reflection on the x-axis.
		@_transposeLayout()
		@_flipLayoutX()

		# TODO: Animate the rotation.
		@object.rotation.y += Math.PI / 2

		# This is sort of lame but, computationally speaking, we will only make
		# at most 4 recursive calls.
		rotations = (rotations - 1) % 4
		@rotateRight(rotations)

	rotateLeft: (rotations = 1) ->
		return @placeOn(@tile) if rotations < 1

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