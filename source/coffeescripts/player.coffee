THREE = require('three')
TWEEN = require('tween')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Player
	constructor: (@room) ->
		@speed = 0.25
		@tile = null

		# Use a temporary mesh.
		geometry = new THREE.CubeGeometry(Const.tileSize, Const.tileSize, Const.tileSize)
		material = new THREE.MeshBasicMaterial(color: 0x777777)
		mesh = new THREE.Mesh(geometry, material)

		@object = mesh
		@object

	# TODO: Using the speed time to chain animations is a hack. Use TWEEN.js's
	# chaining system to chain animations.
	moveAlong: (path) ->
		return unless path.length

		coordPair = path.shift()
		nextTile = @room.tiles[coordPair[0]][coordPair[1]]
		time = @moveTo(nextTile)

		setTimeout(=>
			@moveAlong(path)
		, time)

	moveTo: (tile) ->
		return unless tile
		return if @tile is tile

		tile = tile.object if tile instanceof Tile

		time = 0
		time = @tile.position.distanceTo(tile.position) / @speed if @tile

		position = @object.position.clone()
		target =
			x: tile.position.x + Const.tileSize / 2,
			y: tile.position.z + Const.tileSize,
			z: tile.position.y + Const.tileSize / 2

		new TWEEN.Tween(position)
			.to(target, time)
			.onUpdate(=> @object.position.copy(position))
			.start()

		@tile = tile
		time