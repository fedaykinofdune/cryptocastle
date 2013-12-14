fs     = require('fs')
THREE  = require('three')
TWEEN  = require('tween')
PF     = require('pathfinding')
$      = require('jquery')

Props  = require('./props')
Room   = require('./room')
Const  = require('./constants')
Player = require('./player')

class Game
	@modes: normal: 0, edit: 1

	constructor: ->
		@mode = Game.modes.normal
		@mousePos = null
		@prevIntersectedTile = null
		@xFloor = 10
		@yFloor = 10
		@yWall = 5

		@_setupRenderer()
		@_setupScene()
		@_setupDOM()
		@_setupEvents()

		@grid = new PF.Grid(@xFloor, @yFloor)
		@pathfinder = new PF.AStarFinder(allowDiagonal: true, dontCrossCorners: true)

		# Add a test mesh.
		geometry = new THREE.CubeGeometry(50, 50, 50)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@mesh.position.y = 100
		@scene.add(@mesh)

		@room = new Room(@xFloor, @yWall, @yFloor)
		@scene.add(@room.object)
		@scene.add(new THREE.AxisHelper(200))

		# Add a light.
		roomCenter = @room.tiles[Math.floor(@xFloor / 2)][Math.floor(@yFloor / 2)].notch()
		light = new THREE.PointLight()
		light.position.set(roomCenter.x, @yWall * Const.tileSize, roomCenter.z);
		@scene.add(light)

		# Add a dice table.
		table = new Props.DiceTable()
		@placeOn(table, @room.tiles[Math.floor(@xFloor / 2) - 1][1])

		# Add a player.
		@player = new Player(@room)
		@player.placeOn(@room.tiles[@xFloor - 1][Math.floor(@yFloor / 2)])
		@scene.add(@player.object)

	placeOn: (prop, tile) ->
		prop.placeOn(tile)
		@_gridSetPropWalkable(prop, false)
		@scene.add(prop.object)

	rotateRight: (prop) ->
		@_gridSetPropWalkable(prop)
		prop.rotateRight()	
		@_gridSetPropWalkable(prop, false)

	rotateLeft: (prop) ->
		@_gridSetPropWalkable(prop)
		prop.rotateLeft()
		@_gridSetPropWalkable(prop, false)

	run: ->
		requestAnimationFrame(@run.bind(@))
		TWEEN.update()
		@mesh.rotation.x += 0.005
		@mesh.rotation.y += 0.01

		@_handleTileIntersection()
		@renderer.render(@scene, @camera)

	# Considering a prop and it's pivot tile, place the prop on the AI grid.
	_gridSetPropWalkable: (prop, walkable = true) ->
		for x in [0...prop.xGridSize()]
			for y in [0...prop.yGridSize()]
				xIndex = x + prop.tile.xGrid - prop.xPivot
				yIndex = y + prop.tile.yGrid - prop.yPivot
				@grid.setWalkableAt(xIndex, yIndex, walkable)

	# TODO: Don't light up tiles. In fact, the tiles should not even have
	# meshes. Instead light up the Face3s of the floor.
	_handleTileIntersection: ->
		return unless @mousePos

		intersectedTile = @_getIntersectedTile()
		unless intersectedTile
			return @prevIntersectedTile?.visible = false

		if intersectedTile isnt @prevIntersectedTile
			intersectedTile.visible = true
			@prevIntersectedTile?.visible = false
			@prevIntersectedTile = intersectedTile

	_getIntersectedTile: ->
		ray = @projector.pickingRay(@mousePos.clone(), @camera)
		intersects = ray.intersectObjects(@scene.children, true)

		for intersect in intersects when intersect.object.parent.id is @room.floor.id
			# There are twice as many Face3 objects as our Tile objects so we
			# need to map to our range.
			return intersect.object

	_getMousePosition: (event) ->
		event.preventDefault()
		@mousePos ?= new THREE.Vector3(0, 0, 0.5)
		@mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

	_movePlayer: (event) ->
		event.preventDefault()
		intersectedTileMesh = @_getIntersectedTile()

		targetTile = @room.mesh2tileObj(intersectedTileMesh)

		return unless targetTile
		return if targetTile is @player.targetTile

		path = @pathfinder.findPath(
			@player.tile.xGrid
			@player.tile.yGrid
			targetTile.xGrid
			targetTile.yGrid
			@grid.clone())	

		@player.moveAlong(path)

	_setGameMode: (@mode) ->
		radios = @uiNode.find('.game-modes input')
		radios.prop('checked', false)
		radios.eq(@mode).prop('checked', true)

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

	_setupDOM: ->
		@uiNode = $(fs.readFileSync("#{__dirname}/templates/ui.html"))
		$('body').append(@renderer.domElement)
		$('body').append(@uiNode)

	_setupEvents: ->
		$(@renderer.domElement).click(@_movePlayer.bind(@))
		$(document).mousemove(@_getMousePosition.bind(@))
		$(document).keydown(@_handleHotkey.bind(@))
		$(window).resize(@_updateGameSize.bind(@))
$ ->
	game = new Game()
	game.run()