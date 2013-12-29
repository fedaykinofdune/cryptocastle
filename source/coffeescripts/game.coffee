THREE  = require('three')
TWEEN  = require('tween')
io     = require('socket.io-client')
$      = require('jquery')
_      = require('underscore')

HUD    = require('./hud')
Props  = require('./props')
Room   = require('./room')
Const  = require('./constants')
Player = require('./player')

class Game
	_mode: Const.gameModes.normal
	_hud: null
	_projector: null
	_renderer: null
	_scene: null
	_camera: null
	_socket: null
	_player: null
	_room: null
	_mousePos: null
	_activeTile: null
	_mesh2objectHash: {}
	_props: {}
	_liftPoint: null
	_liftedOriginalPosition: null
	_liftedProp: null
	_liftedPropGhost: null

	constructor: ->
		@_projector = new THREE.Projector()
		@_renderer = new THREE.WebGLRenderer()
		@_renderer.setSize(window.innerWidth, window.innerHeight)

		@_setupScene()
		@_setupSocket()
		@_setupDOM()
		@_setupEvents()

	setMode: (@_mode) ->

	liftProp: (prop) ->
		copy = prop.clone()
		copy.object.visible = false
		copy.object.material.transparent = true
		copy.object.material.opacity = 0.5

		# Make sure the ghost mesh gets dragged at its pivot point. We check if
		# copy.tile exists since a prop can be lifted without having first been
		# placed in the room (like in the case of buying a prop: the ghost mesh
		# appears without the real one having been placed).
		if copy.tile
			copy.xPivot += (@_activeTile.xGrid - copy.tile.xGrid)
			copy.yPivot += (@_activeTile.yGrid - copy.tile.yGrid)

		@_scene.add(copy.object)
		@_setLiftedProp(prop, copy)

	run: ->
		requestAnimationFrame(@run.bind(@))
		TWEEN.update()

		@_handleTileMouseover()
		@_handleLiftedPropHover()
		@_renderer.render(@_scene, @_camera)

	_setupSocket: ->
		@_socket = new io.connect(location.origin)
		@_socket.on('init', (response) =>
			@_setupWorld(response._world)
		)
		@_socket.on('createProp', (response) =>
			@_placePropFromJSON(response.data, @_room.tiles[response.x][response.y])
		)
		@_socket.on('removeProp', (response) =>
			@_room.removeProp(@_props[response.id])
		)
		@_socket.on('moveProp', (response) =>
			prop = @_props[response.id]
			if prop.type is 'player'
				@_room.movePlayer(prop, response.x, response.y)
			else
				@_room.placeProp(prop, response.x, response.y)
		)

	_setupDOM: ->
		@_hud = new HUD(@)
		$('body').append(@_hud.el)
		$('body').append(@_renderer.domElement)

	_setupScene: ->
		@_scene = new THREE.Scene()

		width = window.innerWidth / 2
		height = window.innerHeight / 2
		@_camera = new THREE.OrthographicCamera(-width, width, height, -height, -500, 1000)
		@_camera.position = new THREE.Vector3(100, 100, 100)
		@_camera.scale.set(0.4, 0.4, 0.4)
		@_camera.lookAt(Const.origin)
		@_camera.position.x /= 2
		@_camera.position.z /= 2

	_setupWorld: (world) ->
		xFloor = world.length
		yFloor = world[0].length
		yWall = 5

		@_room = new Room(xFloor, yWall, yFloor, world)
		@_scene.add(@_room.object)
		@_scene.add(new THREE.AxisHelper(200))
		@_mapClickableMeshes(@_room.tiles)

		# Add a light.
		roomCenter = @_room.tiles[Math.floor(xFloor / 2)][Math.floor(yFloor / 2)].notch()
		light = new THREE.PointLight()
		light.position.set(roomCenter.x, yWall * Const.tileSize, roomCenter.z);
		@_scene.add(light)

		@_room.eachTile((tile, x, y) =>
			@_placePropFromJSON(world[x][y], tile)
		)

	_setupEvents: ->
		$(@_renderer.domElement).click(@_handleGameClick.bind(@))
		$(document).bind('contextmenu', @_handleRightClick.bind(@))
		$(document).mousemove(@_getMousePosition.bind(@))
		$(document).keydown(@_handleHotkey.bind(@))
		$(window).resize(@_updateGameSize.bind(@))

	_removeProp: (prop) ->
		@_unmapClickableMeshes(prop)
		@_room.removeProp(prop)
		@_scene.remove(prop.object)

	# TODO: Make all these placeProp-type contracts use x, y rather than tile.
	# Tiles are sort of internal things to the Room.
	_placePropFromJSON: (json, tile) ->
		return unless json

		prop = null
		switch json.type
			when 'player'
				prop = Player.createFromJSON(json).render()
				prop.room = @_room
				@_player = prop if prop.currentPlayer

			when 'diceTable'
				prop = Props.DiceTable.createFromJSON(json)

			when 'chair'
				return

		@_props[prop.id] = prop
		@_placeProp(prop, tile)

	_placeProp: (prop, tile) ->
		@_mapClickableMeshes(prop)
		@_room.placeProp(prop, tile)
		@_scene.add(prop.object)

	_rotateRightProp: (prop) ->
		@_room.unsetCollisionFor(prop)
		prop.rotateRight()	
		@_room.setCollisionFor(prop)

	_rotateLeftProp: (prop) ->
		@_room.unsetCollisionFor(prop)
		prop.rotateLeft()
		@_room.setCollisionFor(prop)

	_forgetLiftedProp: -> 
		@_liftPoint = null
		@_liftedOriginalPosition = null
		@_liftedProp = null
		@_liftedPropGhost = null

	_setLiftedProp: (original, ghost) ->
		@_liftPoint = @_getIntersectedPoint('tile')
		@_liftedOriginalPosition = original.object.position.clone()
		@_liftedProp = original
		@_liftedPropGhost = ghost

	# Entities can be a single prop, an array or nested array of entities.
	# Useful for being able to pass in a single Prop or a 2D array of Tiles.
	_eachProp: (entities, callback) ->
		entities = [entities] unless entities.length

		# We use _.flatten for convenience since entities could be passed in as
		# a 2D array of tiles.
		callback(prop) for prop in _.flatten(entities)

	# Used to map, say, a prop mesh to its respective Prop object.
	_mapClickableMeshes: (entities) ->
		@_eachProp(entities, (prop) =>
			@_mesh2objectHash[prop.object.id] = prop
		)

	_unmapClickableMeshes: (entities) ->
		@_eachProp(entities, (prop) =>
			delete @_mesh2objectHash[prop.object.id]
		)

	# This mapping is useful when Game does a raycast and picks out some mesh in
	# the scene. Now it can find the corresponding object in O(1) time.
	_mesh2object: (mesh) -> @_mesh2objectHash[mesh.id]

	# TODO: There's a bug where the active tile can be just outside the prop
	# while still selecting the prop for dragging. It's a minor bug but it can
	# be fixed by adjusting the active tile to be the one directly under the
	# prop intersection point.
	_handleLiftedPropHover: ->
		return unless @_liftedPropGhost

		# It's possible to buy an item in the shop without having moved the
		# mouse on the game screen yet. This makes sure the prop is hidden until
		# we have some positioning info.
		if @_activeTile or @_liftPoint
			@_liftedPropGhost.object.visible = true

		if @_activeTile
			@_liftedPropGhost.placeOn(@_activeTile)
			@_activeTile.object.visible = false

		else if @_liftPoint
			# TODO: Push this logic into Prop. Also don't use the tile for
			# intersection. Use an invisible plane so the prop can hover on the
			# mouse pointer anywhere.
			point = @_getIntersectedPoint('tile')
			delta = @_liftPoint.clone().sub(point)
			@_liftedPropGhost.object.position.subVectors(@_liftedOriginalPosition, delta)

	# TODO: Don't light up tiles. In fact, the tiles should not even have
	# meshes. Instead light up the Face3s of the floor.
	_handleTileMouseover: ->
		mesh = @_getIntersectedMesh('tile')
		tileMesh = @_activeTile?.object
		unless mesh
			return tileMesh?.visible = false

		if mesh isnt tileMesh
			tileMesh?.visible = false
			if mesh.name is 'tile'
				mesh.visible = true
				@_activeTile = @_mesh2object(mesh)

	# Gets all ray intersections from the mouse pointer.
	_getIntersections: ->
		return [] unless @_mousePos
		ray = @_projector.pickingRay(@_mousePos.clone(), @_camera)
		intersections = ray.intersectObjects(@_scene.children, true)

		# Filter out some dumb shit like axis helper, lights etc.
		_.filter(intersections, (item) => @_mesh2object(item.object))

	# Gets the first ray intersection from the mouse pointer.
	_getIntersection: (nameFilter = null) ->
		for intersect in @_getIntersections()
			# Apply the name filter.
			continue if nameFilter and intersect.object.name isnt nameFilter
			return intersect

	_getIntersectedMesh: (nameFilter = null) ->
		@_getIntersection(nameFilter)?.object

	_getIntersectedPoint: (nameFilter = null) ->
		@_getIntersection(nameFilter)?.point

	_getMousePosition: (event) ->
		event.preventDefault()
		@_mousePos ?= new THREE.Vector3(0, 0, 0.5)
		@_mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@_mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

		# TODO: Get the intersected mesh on each mousemove event. Use it here to
		# set the CSS grab icon when appropriate.

	# TODO: This function is becoming a tangled mess. If there are more game
	# states we could benefit from a finite state machine.
	_handleGameClick: (event) ->
		event.preventDefault()

		tileMesh = @_getIntersectedMesh('tile')
		propMesh = @_getIntersectedMesh('prop')

		return unless tileMesh or propMesh

		switch @_mode
			when Const.gameModes.normal
				@_sendMovePlayerRequest(@_mesh2object(tileMesh)) if tileMesh

			when Const.gameModes.edit
				# If we clicked on a mesh and we're not carrying a prop.
				if propMesh and not @_liftedPropGhost
					@liftProp(@_mesh2object(propMesh))
					@_hud.disableShop()

				# If we clicked on a tile and we're carrying a prop.
				else if tileMesh and @_liftedPropGhost

					# We remove @_liftedProp before anything else because
					# sometimes we want to replace it in a way that overlaps its
					# original position. We don't want that original position to
					# get in the way of our placement computations.
					liftedPropTile = @_liftedProp.tile
					@_removeProp(@_liftedProp)

					tile = @_mesh2object(tileMesh)
					if @_room.propFitsOn(@_liftedPropGhost, tile)
						@_liftedPropGhost.object.material.opacity = 1
						@_liftedPropGhost.object.material.transparent = false
						@_placeProp(@_liftedPropGhost, tile)
						@_forgetLiftedProp()
						@_hud.enableShop()
					else
						@_placeProp(@_liftedProp, liftedPropTile)

	_handleRightClick: (event) ->
		event.preventDefault()
		if Const.gameModes.edit and @_liftedPropGhost
			@_liftedPropGhost.rotateRight()

	_sendMovePlayerRequest: (tile) ->
		return if tile is @_player.tile
		@_socket.emit('movePropRequest', id: @_player.id, x: tile.xGrid, y: tile.yGrid)

	_handleHotkey: (event) ->
		switch event.which
			when Const.keys.e 
				event.preventDefault()
				@_hud.setGameModeDisplay(Const.gameModes.edit)
			when Const.keys.n 
				event.preventDefault()
				@_hud.setGameModeDisplay(Const.gameModes.normal)

	_updateGameSize: ->
		width = window.innerWidth / 2
		height = window.innerHeight / 2
		@_camera.left = -width
		@_camera.right = width
		@_camera.top = height
		@_camera.bottom = -height

		@_camera.updateProjectionMatrix()
		@_renderer.setSize(window.innerWidth, window.innerHeight) 
$ ->
	game = new Game()
	game.run()