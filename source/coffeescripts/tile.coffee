THREE = require('three')

Const = require('./constants')

module.exports = class Tile 
	constructor: (@xPos, @yPos, @zPos) ->
		@edges = {}

		material = new THREE.MeshBasicMaterial(color: 0xcccccc)
		geometry = new THREE.PlaneGeometry(Const.tileSize, Const.tileSize)
		tile = new THREE.Mesh(geometry, material)
		tile.position.x = @xPos
		tile.position.y = @yPos
		tile.position.z = @zPos - 1
		tile.rotation.y = Math.PI
		tile.visible = false

		@object = tile
		@object

	# Use tile positions to associate them using a direction vector.
	connect: (tile) ->
		return unless tile
		direction = new THREE.Vector2(tile.xPos - @xPos, tile.yPos - @yPos)
		direction = direction.divideScalar(Const.tileSize)
		@edges["#{direction.x} #{direction.y}"] = tile