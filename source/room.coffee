THREE = require('three')
PF	= require('pathfinding')
_	 = require('underscore')

Tile  = require('./tile')
Const = require('./constants')

module.exports = class Room
	tiles: []

	_xFloor: null
	_yFloor: null
	_yWall: null
	_grid: null
	_pathfinder: null
	_world: null

	constructor: (@_world, @_yWall = 5) ->
		# TODO: Combine @tiles and @_world. Right now @tiles is dictated by
		# geometry which is dictated by @_xFloor, @_yWall, @_yFloor. It should
		# be that @_world is served up by the server, which determines @_xFloor,
		# @_yFloor which determines geometry and populates @tiles from @_world
		# data internally.
		@_xFloor = @_world[0].length
		@_yFloor = @_world.length

		@_grid = new PF.Grid(@_xFloor, @_yFloor, @_world)
		@_pathfinder = new PF.AStarFinder(allowDiagonal: true, dontCrossCorners: true)

		sizeX = Const.tileSize * @_xFloor
		sizeY = Const.tileSize * @_yWall
		sizeZ = Const.tileSize * @_yFloor

		# Build the isometric room. 

		# TODO: Move this stuff to a render function so that the back-end isn't
		# running all this needlessly. 
		geometry = new THREE.Geometry()

		geometry.vertices.push(new THREE.Vector3(sizeX / 2, 0, -sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(-sizeX / 2, 0, -sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(-sizeX / 2, 0, sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(sizeX / 2, 0, sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(sizeX / 2, sizeY / 2, -sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(-sizeX / 2, sizeY / 2, -sizeZ / 2))
		geometry.vertices.push(new THREE.Vector3(-sizeX / 2, sizeY / 2, sizeZ / 2))

		geometry.faces.push(new THREE.Face3(0, 1, 2))
		geometry.faces.push(new THREE.Face3(0, 2, 3))
		geometry.faces.push(new THREE.Face3(0, 4, 5))
		geometry.faces.push(new THREE.Face3(0, 1, 5))
		geometry.faces.push(new THREE.Face3(1, 2, 6))
		geometry.faces.push(new THREE.Face3(1, 5, 6))

		material = new THREE.MeshLambertMaterial(
			color: 0xff0000
			side: THREE.DoubleSide
		)

		@object = new THREE.Mesh(geometry, material)	

		# @_setupTiles(floor)

	toJSON: -> 
		_world: @_world

	tileAt: (x, y) -> @tiles[y]?[x]

	movePlayer: (player, x, y) ->
		@unsetCollisionFor(player)
		tile = @nearestFreeTile(player.tile, @tileAt(x, y))
		path = @_pathfinder.findPath(
			player.tile.xGrid
			player.tile.yGrid
			tile.xGrid
			tile.yGrid
			@_grid.clone())	

		player.moveAlong(path)
		@setCollisionFor(player)

	placeProp: (prop, x, y) ->
		tile = if x instanceof Tile then x else @tileAt(x, y)
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
				console.log "#{distance} #{nearestDistance}"
				if distance < nearestDistance
					nearestDistance = distance
					nearestTile = tile
			)

			if nearestTile
				console.log "nearest tile!"
				console.log "#{nearestTile.xGrid} #{nearestTile.yGrid}"
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
		@_world[prop.tile.yGrid][prop.tile.xGrid] = 0 if prop.tile

		prop.eachTile((xIndex, yIndex) =>
			@_grid.setWalkableAt(xIndex, yIndex, true)
		)

	setCollisionFor: (prop) ->
		@_world[prop.tile.yGrid][prop.tile.xGrid] = prop if prop.tile

		prop.eachTile((xIndex, yIndex) =>
			@_grid.setWalkableAt(xIndex, yIndex, false)
		)

	eachTile: (callback) ->
		for y in [0...@_yFloor]		
			for x in [0...@_xFloor]
				value = callback(@tileAt(x, y), x, y)
				return @tileAt(x, y) if value is false

	# TODO: Replace this with a hash lookup rather than linear iteration.
	mesh2tileObj: (mesh) ->
		@eachTile((tile, x, y) =>
			false if @tileAt(x, y).object is mesh
		)

	# Iterate an outer ring around a given tile. Useful for Room.nearestFreeTile
	# function.
	eachTileRing: (centerTile, radius, callback) ->
		return callback(centerTile) if radius is 0

		for x in [(centerTile.xGrid - radius)...(centerTile.xGrid + radius)]
			tileBottom = @tileAt(x, centerTile.yGrid + radius)
			tileTop = @tileAt(x, centerTile.yGrid - radius)
			callback(tileTop) if tileTop
			callback(tileBottom) if tileBottom

		for y in [(centerTile.yGrid - radius + 1)...(centerTile.yGrid + radius - 1)]
			tileLeft = @tileAt(centerTile.xGrid - radius, y)
			tileRight = @tileAt(centerTile.xGrid + radius, y)
			callback(tileLeft) if tileLeft
			callback(tileRight) if tileRight

	_setupTiles: (floor) ->
		# Build tiles based on the faces of the floor.
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

			tileIndex = index / 2
			xIndex = tileIndex % @_xFloor
			yIndex = Math.floor(tileIndex / @_xFloor)

			tile = new Tile(centroid.x, centroid.y, centroid.z - 1, xIndex, yIndex)

			@tiles[yIndex] ?= []
			@tiles[yIndex][xIndex] = tile
			floor.add(tile.object)