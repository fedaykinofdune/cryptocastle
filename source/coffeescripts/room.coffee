THREE = require('three')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Room
	constructor: (@xTiles, @yTiles, @zTiles) ->
		console.log('Room code!')

		sizeX = Const.tileSize * @xTiles
		sizeY = Const.tileSize * @yTiles
		sizeZ = Const.tileSize * @zTiles

		# Build the isometric room.
		material = new THREE.MeshNormalMaterial()
		material.side = THREE.DoubleSide

		@floor = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeY), material)
		leftWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeY, sizeZ), material)
		rightWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeZ), material)

		@floor.rotation.x = Math.PI / 2
		leftWall.rotation.y = Math.PI / 2
		leftWall.rotation.z = Math.PI / 2
		leftWall.position = new THREE.Vector3(-sizeX / 2, 0, -sizeZ / 2)
		rightWall.rotation.x = Math.PI / 2
		rightWall.rotation.y = Math.PI
		rightWall.position = new THREE.Vector3(0, -sizeY / 2, -sizeZ / 2)

		@floor.add(leftWall)
		@floor.add(rightWall)

		@_setupTiles(@floor.geometry.vertices[2])

		@object = @floor
		@object

	_eachTile: (callback) ->
		for y in [0...@yTiles]		
			for x in [0...@xTiles]
				callback(@tiles[x][y], x, y)

	_setupTiles: (floorCorner) ->
		# Build a 2D array of tiles.
		@tiles = []
		for x in [0...@xTiles]
			@tiles.push(
				for y in [0...@yTiles]
					xPos = floorCorner.x + (x * Const.tileSize) + (Const.tileSize / 2)
					yPos = floorCorner.y + (y * Const.tileSize) + (Const.tileSize / 2)
					new Tile(xPos, yPos, floorCorner.z)
			)

		# Connect each tile to it's neighbours at sides and vertices.
		@_eachTile((tile, x, y) =>
			tile.connect(@tiles[x + 1]?[y])
			tile.connect(@tiles[x + 1]?[y + 1])
			tile.connect(@tiles[x]?[y + 1])
			tile.connect(@tiles[x - 1]?[y + 1])
			tile.connect(@tiles[x - 1]?[y])
			tile.connect(@tiles[x - 1]?[y - 1])
			tile.connect(@tiles[x]?[y - 1])
			tile.connect(@tiles[x + 1]?[y - 1])
			@floor.add(tile.object)
		)
