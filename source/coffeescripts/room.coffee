THREE = require('three')
_     = require('underscore')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Room
	constructor: (@xTiles, @yTiles, @zTiles) ->
		sizeX = Const.tileSize * @xTiles
		sizeY = Const.tileSize * @yTiles
		sizeZ = Const.tileSize * @zTiles

		# Build the isometric room. 
		# TODO: Build the room mesh without several plane meshes and a rotation.
		# Allow passing in an arbitrary 2d array of tile layout and procedurally
		# generate the vertices for the walls and floors that will bound those
		# tiles. This will create a custom THREE.Geometry. Now a rotation isn't
		# necessary.
		material = new THREE.MeshNormalMaterial()
		material.side = THREE.DoubleSide
		floor = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeZ, @xTiles, @zTiles), material)
		leftWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeY), material)
		rightWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeY, sizeZ), material)

		floor.rotation.x = Math.PI / 2
		leftWall.rotation.y = Math.PI / 2
		leftWall.position = new THREE.Vector3(-sizeX / 2, sizeY / 2, 0)
		rightWall.rotation.z = Math.PI / 2
		rightWall.position = new THREE.Vector3(0, sizeY / 2, -sizeZ / 2)

		@object = new THREE.Object3D()
		@object.add(floor)
		@object.add(leftWall)
		@object.add(rightWall)

		@_setupTiles(floor)

		@object

	# TODO: Replace this with a hash lookup rather than linear iteration.
	mesh2tileObj: (mesh) ->
		for y in [0...@zTiles]		
			for x in [0...@xTiles]
				return @tiles[x][y] if @tiles[x][y].object is mesh

	_eachTile: (callback) ->
		for y in [0...@zTiles]		
			for x in [0...@xTiles]
				callback(@tiles[x][y], x, y)

	_setupTiles: (floor) ->
		# Build tiles based on the faces of the floor.
		@tiles = []
		geometry = floor.geometry
		for face, index in geometry.faces by 2
			otherFace = geometry.faces[index + 1]
			vertices = _.uniq([
				geometry.vertices[face.a]
				geometry.vertices[face.b]
				geometry.vertices[face.c]
				geometry.vertices[otherFace.a]
				geometry.vertices[otherFace.b]
				geometry.vertices[otherFace.c]
			])

			centroid = new THREE.Vector3()
			centroid.add(vertex) for vertex in vertices
			centroid.divideScalar(vertices.length)

			xIndex = Math.floor(index / @xTiles / 2)
			@tiles[xIndex] ?= []
			yIndex = @tiles[xIndex].length
			@tiles[xIndex][yIndex] = new Tile(centroid.x, centroid.y, centroid.z - 1, xIndex, yIndex)

		# Connect each tile to it's neighbours at sides and vertices.
		# TODO: This code can likely go away since we are using Pathfinding.js
		# instead of our own AI.
		@_eachTile((tile, x, y) =>
			tile.connect(@tiles[x + 1]?[y])
			tile.connect(@tiles[x + 1]?[y + 1])
			tile.connect(@tiles[x]?[y + 1])
			tile.connect(@tiles[x - 1]?[y + 1])
			tile.connect(@tiles[x - 1]?[y])
			tile.connect(@tiles[x - 1]?[y - 1])
			tile.connect(@tiles[x]?[y - 1])
			tile.connect(@tiles[x + 1]?[y - 1])
			floor.add(tile.object)
		)