fs     = require('fs')
THREE  = require('three')
TWEEN  = require('tween')
PF     = require('pathfinding')
$      = require('jquery')
_ 	   = require('underscore')

Props  = require('./props')
Room   = require('./room')
Const  = require('./constants')
Player = require('./player')

class Game
	@modes: normal: 0, edit: 1

	constructor: ->
		@mode = Game.modes.normal
		@mousePos = null
		@activeTile = null
		@mesh2objectHash = {}
		@xFloor = 10
		@yFloor = 10
		@yWall = 5
		@_clearLiftedProp()

		@grid = new PF.Grid(@xFloor, @yFloor)
		@pathfinder = new PF.AStarFinder(allowDiagonal: true, dontCrossCorners: true)

		@_setupRenderer()
		@_setupScene()
		@_setupDOM()
		@_setupEvents()

	liftProp: (prop) ->
		copy = prop.clone()
		copy.object.material.transparent = true
		copy.object.material.opacity = 0.5

		# Make sure the ghost mesh gets dragged at its pivot point.
		copy.xPivot += (@activeTile.xGrid - copy.tile.xGrid)
		copy.yPivot += (@activeTile.yGrid - copy.tile.yGrid)

		@scene.add(copy.object)
		@_setLiftedProp(prop, copy)

	removeProp: (prop) ->
		@_unmapClickableMeshes(prop)
		@_gridSetPropWalkable(prop)
		@scene.remove(prop.object)
		@_clearLiftedProp() if prop is @liftedProp

	placeProp: (prop, tile) ->
		@_mapClickableMeshes(prop)
		prop.placeOn(tile)
		@_gridSetPropWalkable(prop, false)
		@scene.add(prop.object)

	rotateRightProp: (prop) ->
		@_gridSetPropWalkable(prop)
		prop.rotateRightProp()	
		@_gridSetPropWalkable(prop, false)

	rotateLeftProp: (prop) ->
		@_gridSetPropWalkable(prop)
		prop.rotateLeftProp()
		@_gridSetPropWalkable(prop, false)

	run: ->
		requestAnimationFrame(@run.bind(@))
		TWEEN.update()
		@mesh.rotation.x += 0.005
		@mesh.rotation.y += 0.01

		@_handleTileMouseover()
		@_handleLiftedPropHover()
		@renderer.render(@scene, @camera)

	_clearLiftedProp: -> 
		@liftPoint = null
		@liftedOriginalPosition = null
		@liftedProp = null
		@liftedPropGhost = null

	_setLiftedProp: (original, ghost) ->
		@liftPoint = @_getIntersectedPoint('tile')
		@liftedOriginalPosition = original.object.position.clone()
		@liftedProp = original
		@liftedPropGhost = ghost

	# Entities can be a single entity, an array or nested array of entities.
	# Useful for being able to pass in a single Prop or a 2D array of Tiles.
	_eachEntity: (entities, callback) ->
		entities = [entities] unless entities.length

		# We use _.flatten for convenience since entities could be passed in as
		# a 2D array of tiles.
		callback(entity) for entity in _.flatten(entities)

	# Used to map, say, a prop mesh to its respective Prop object.
	_mapClickableMeshes: (entities) ->
		@_eachEntity(entities, (entity) =>
			@mesh2objectHash[entity.object.id] = entity
		)

	_unmapClickableMeshes: (entities) ->
		@_eachEntity(entities, (entity) =>
			delete @mesh2objectHash[entity.object.id]
		)

	_mesh2object: (mesh) -> @mesh2objectHash[mesh.id]

	# Considering a prop and it's pivot tile, place the prop on the AI grid.
	_gridSetPropWalkable: (prop, walkable = true) ->
		for x in [0...prop.xGridSize()]
			for y in [0...prop.yGridSize()]
				xIndex = x + prop.tile.xGrid - prop.xPivot
				yIndex = y + prop.tile.yGrid - prop.yPivot
				@grid.setWalkableAt(xIndex, yIndex, walkable)

	# TODO: There's a bug where the active tile can be just outside the prop
	# while still selecting the prop for dragging. It's a minor bug but it can
	# be fixed by adjusting the active tile to be the one directly under the
	# prop intersection point.
	_handleLiftedPropHover: ->
		return unless @liftedPropGhost
		if @activeTile
			@liftedPropGhost.placeOn(@activeTile)
			@activeTile.object.visible = false
		else
			# TODO: Push this logic into Prop. Also don't use the tile for
			# intersection. Use an invisible plane so the prop can hover on the
			# mouse pointer anywhere.
			point = @_getIntersectedPoint('tile')
			delta = @liftPoint.clone().sub(point)
			@liftedPropGhost.object.position.subVectors(@liftedOriginalPosition, delta)

	# TODO: Don't light up tiles. In fact, the tiles should not even have
	# meshes. Instead light up the Face3s of the floor.
	_handleTileMouseover: ->
		mesh = @_getIntersectedMesh('tile')
		tileMesh = @activeTile?.object
		unless mesh
			return tileMesh?.visible = false

		if mesh isnt tileMesh
			tileMesh?.visible = false
			if mesh.name is 'tile'
				mesh.visible = true
				@activeTile = @_mesh2object(mesh)

	_getIntersection: (nameFilter = null) ->
		return unless @mousePos
		ray = @projector.pickingRay(@mousePos.clone(), @camera)
		intersects = ray.intersectObjects(@scene.children, true)
		for intersect in intersects
			continue unless @_mesh2object(intersect.object)
			continue if nameFilter and intersect.object.name isnt nameFilter
			return intersect

	_getIntersectedMesh: (nameFilter = null) ->
		@_getIntersection(nameFilter)?.object

	_getIntersectedPoint: (nameFilter = null) ->
		@_getIntersection(nameFilter)?.point

	_getMousePosition: (event) ->
		event.preventDefault()
		@mousePos ?= new THREE.Vector3(0, 0, 0.5)
		@mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

		# TODO: Get the intersected mesh on each mousemove event. Use it here to
		# set the CSS grab icon when appropriate.

	# Game uses @xFloor, @yFloor along with tile grid info and prop dimensions
	# to determine if the prop will fit on the tile.
	_propFitsOn: (tile, prop) ->
		return false if tile.xGrid + prop.xGridSize() - prop.xPivot > @xFloor
		return false if tile.xGrid - prop.xPivot < 0
		return false if tile.yGrid + prop.yGridSize() - prop.yPivot > @yFloor	
		return false if tile.yGrid - prop.yPivot < 0
		true

	_handleGameClick: (event) ->
		event.preventDefault()

		intersectedMesh = @_getIntersectedMesh()
		return unless intersectedMesh

		object = @_mesh2object(intersectedMesh)
		switch @mode
			when Game.modes.edit
				if intersectedMesh.name is 'tile' and @liftedPropGhost
					if @_propFitsOn(object, @liftedPropGhost)
						@liftedPropGhost.object.material.opacity = 1
						@liftedPropGhost.object.material.transparent = false
						@placeProp(@liftedPropGhost, object)
						@removeProp(@liftedProp)
				if intersectedMesh.name is 'prop' and not @liftedProp
					@liftProp(object)

			when Game.modes.normal
				if intersectedMesh.name is 'tile'
					@_playerMoveAlong(object)

	_handleRightClick: (event) ->
		event.preventDefault()
		if Game.modes.edit and @liftedPropGhost
			@liftedPropGhost.rotateRight()

	_playerMoveAlong: (tile) ->
		return if tile is @player.tile

		path = @pathfinder.findPath(
			@player.tile.xGrid
			@player.tile.yGrid
			tile.xGrid
			tile.yGrid
			@grid.clone())	

		@player.moveAlong(path)

	_setGameMode: (@mode) ->
		radios = @uiNode.find('.game-modes input')
		radios.prop('checked', false)
		radios.eq(@mode).prop('checked', true)
				
	_handleUIClick: (event) ->
		mode = Game.modes[event.target.value]
		@mode = mode if mode

	_handleHotkey: (event) ->
		switch event.which
			when Const.keys.e 
				event.preventDefault()
				@_setGameMode(Game.modes.edit)
			when Const.keys.n 
				event.preventDefault()
				@_setGameMode(Game.modes.normal)

	_updateGameSize: ->
		width = window.innerWidth / 2
		height = window.innerHeight / 2
		@camera.left = -width
		@camera.right = width
		@camera.top = height
		@camera.bottom = -height

		@camera.updateProjectionMatrix()
		@renderer.setSize(window.innerWidth, window.innerHeight) 

	_setupRenderer: ->
		@projector = new THREE.Projector()
		@renderer = new THREE.WebGLRenderer()
		@renderer.setSize(window.innerWidth, window.innerHeight)

	_setupScene: ->
		@scene = new THREE.Scene()

		width = window.innerWidth / 2
		height = window.innerHeight / 2
		@camera = new THREE.OrthographicCamera(-width, width, height, -height, -500, 1000)
		@camera.position = new THREE.Vector3(100, 100, 100)
		@camera.scale.set(0.4, 0.4, 0.4)
		@camera.lookAt(Const.origin)
		@camera.position.x /= 2
		@camera.position.z /= 2

		# Add a test mesh.
		geometry = new THREE.CubeGeometry(50, 50, 50)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@mesh.position.y = 100
		@scene.add(@mesh)

		@room = new Room(@xFloor, @yWall, @yFloor)
		@scene.add(@room.object)
		@scene.add(new THREE.AxisHelper(200))
		@_mapClickableMeshes(@room.tiles)

		# Add a light.
		roomCenter = @room.tiles[Math.floor(@xFloor / 2)][Math.floor(@yFloor / 2)].notch()
		light = new THREE.PointLight()
		light.position.set(roomCenter.x, @yWall * Const.tileSize, roomCenter.z);
		@scene.add(light)

		# Add a dice table.
		table = new Props.DiceTable()
		@placeProp(table, @room.tiles[Math.floor(@xFloor / 2) - 1][1])

		# Add a player.
		@player = new Player(@room)
		@player.placeOn(@room.tiles[@xFloor - 1][Math.floor(@yFloor / 2)])
		@scene.add(@player.object)

	_setupDOM: ->
		@uiNode = $(fs.readFileSync("#{__dirname}/templates/ui.html"))
		$('body').append(@renderer.domElement)
		$('body').append(@uiNode)

	_setupEvents: ->
		$(@renderer.domElement).click(@_handleGameClick.bind(@))
		$(@uiNode).change(@_handleUIClick.bind(@))
		$(document).bind('contextmenu', @_handleRightClick.bind(@))
		$(document).mousemove(@_getMousePosition.bind(@))
		$(document).keydown(@_handleHotkey.bind(@))
		$(window).resize(@_updateGameSize.bind(@))
$ ->
	game = new Game()
	game.run()