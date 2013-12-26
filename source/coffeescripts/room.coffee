THREE = require('three')
PF    = require('pathfinding')
_     = require('underscore')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Room
	_xFloor: null
	_yFloor: null
	_yWall: null
	_grid: null
	_pathfinder: null
	_world: null

	constructor: (@_xFloor, @_yWall, @_yFloor, @_world) ->
		sizeX = Const.tileSize * @_xFloor
		sizeY = Const.tileSize * @_yWall
		sizeZ = Const.tileSize * @_yFloor

		# TODO: Combine @tiles and @_world.
		@_world ?= (0 for x in [0...@_xFloor] for y in [0...@_yFloor])
		@_grid = new PF.Grid(@_xFloor, @_yFloor, @_world)
		@_pathfinder = new PF.AStarFinder(allowDiagonal: true, dontCrossCorners: true)

		# Build the isometric room. 
		# TODO: Build the room mesh without several plane meshes and a rotation.
		# Allow passing in an arbitrary 2d array of tile layout and procedurally
		# generate the vertices for the walls and floors that will bound those
		# tiles. This will create a custom THREE.Geometry. Now a rotation isn't
		# necessary.
		material = new THREE.MeshNormalMaterial()
		material.side = THREE.DoubleSide
		floor = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeZ, @_xFloor, @_yFloor), material)
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

	toJSON: -> 
		world = (_.map(row, (prop) -> prop and prop.toJSON()) for row in @_world)
		world: @_world

	placeProp: (prop, x, y) ->
		tile = if x instanceof Tile then x else @tiles[x][y]
		prop.placeOn(tile)
		@setCollisionFor(prop)

	removeProp: (prop) ->
		@unsetCollisionFor(prop)
		prop.remove()

	# Find the nearest tile to targetTile from sourceTile that is not occupied.
	nearestFreeTile: (sourceTile, targetTile) ->
		nearestTile = null 
		nearestDistance = Infinity

		for radius in [0...5]
			@eachTileRing(targetTile, radius, (tile) =>
				return unless @_grid.isWalkableAt(tile.xGrid, tile.yGrid)
				distance = sourceTile.object.position.distanceTo(tile.object.position)
				if distance < nearestDistance
					nearestDistance = distance
					nearestTile = tile
			)

			return nearestTile if nearestTile

		sourceTile

	# Room uses @_xFloor, @_yFloor along with tile grid info and prop dimensions
	# to determine if the prop fits on the tile. This is useful when moving
	# around a potential candidate for placement (@_liftedPropGhost).
	propFitsOn: (prop, tile) ->
		return false unless prop and tile

		prop.eachTile((xIndex, yIndex) =>
			return false unless @_grid.isWalkableAt(xIndex, yIndex)
		)
		return false if tile.xGrid + prop.xGridSize() - prop.xPivot > @_xFloor
		return false if tile.xGrid - prop.xPivot < 0
		return false if tile.yGrid + prop.yGridSize() - prop.yPivot > @_yFloor	
		return false if tile.yGrid - prop.yPivot < 0
		true

	# Considering a prop and it's pivot tile, place the prop on the AI grid.
	unsetCollisionFor: (prop) ->
		@_world[prop.tile.xGrid][prop.tile.yGrid] = 0

		prop.eachTile((xIndex, yIndex) =>
			@_grid.setWalkableAt(xIndex, yIndex, true)
		)

	setCollisionFor: (prop) ->
		@_world[prop.tile.xGrid][prop.tile.yGrid] = prop

		prop.eachTile((xIndex, yIndex) =>
			@_grid.setWalkableAt(xIndex, yIndex, false)
		)

	eachTile: (callback) ->
		for x in [0...@_xFloor]
			for y in [0...@_yFloor]		
				value = callback(@tiles[x][y], x, y)
				return @tiles[x][y] if value is false

	# TODO: Replace this with a hash lookup rather than linear iteration.
	mesh2tileObj: (mesh) ->
		@eachTile((tile, x, y) =>
			false if @tiles[x][y].object is mesh
		)

	# Iterate an outer ring around a given tile. Useful for Room.nearestFreeTile
	# function.
	eachTileRing: (centerTile, radius, callback) ->
		return callback(centerTile) if radius is 0

		for x in [(centerTile.xGrid - radius)...(centerTile.xGrid + radius)]
			tileBottom = @tiles[x]?[centerTile.yGrid + radius]
			tileTop = @tiles[x]?[centerTile.yGrid - radius]
			callback(tileTop) if tileTop
			callback(tileBottom) if tileBottom

		for y in [(centerTile.yGrid - radius + 1)...(centerTile.yGrid + radius - 1)]
			tileLeft = @tiles[centerTile.xGrid - radius]?[y]
			tileRight = @tiles[centerTile.xGrid + radius]?[y]
			callback(tileLeft) if tileLeft
			callback(tileRight) if tileRight

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

			xIndex = Math.floor(index / 2 / @_xFloor)
			@tiles[xIndex] ?= []
			yIndex = @tiles[xIndex].length

			tile = new Tile(centroid.x, centroid.y, centroid.z - 1, xIndex, yIndex)
			@tiles[xIndex][yIndex] = tile
			floor.add(tile.object)