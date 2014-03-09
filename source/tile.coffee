THREE = require('three')

Const = require('./constants')

module.exports = class Tile 
	constructor: (@xPos, @yPos, @zPos, @xGrid, @yGrid) ->
		@edges = {}

		material = new THREE.MeshBasicMaterial(color: 0xcccccc)
		material.side = THREE.DoubleSide
		geometry = new THREE.PlaneGeometry(Const.tileSize, Const.tileSize)
		@object = new THREE.Mesh(geometry, material)
		@object.position.set(@xPos, @yPos, @zPos)
		@object.visible = false

		@object.name = 'tile'
		@object

	# Use tile positions to associate them using a direction vector.
	connect: (tile) ->
		return unless tile
		direction = new THREE.Vector2(tile.xPos - @xPos, tile.yPos - @yPos)
		direction = direction.divideScalar(Const.tileSize)
		@edges["#{direction.x} #{direction.y}"] = tile

	notch: ->
		new THREE.Vector3(
			-@object.position.y,
			 @object.position.x,
			 @object.position.z
		)
