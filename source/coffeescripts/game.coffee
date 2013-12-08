THREE  = require('three')
TWEEN  = require('tween')
$      = require('jquery')

Room   = require('./room')
Const  = require('./constants')
Player = require('./player')

class Game
	constructor: ->
		@mousePos = null
		@prevIntersectedTile = null

		@_setupRenderer()
		@_setupScene()

		# Add a test mesh.
		geometry = new THREE.CubeGeometry(50, 50, 50)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@mesh.position.y = 100
		@scene.add(@mesh)

		$(document).mousemove(@_getMousePosition.bind(@))
		$(document).click(@_movePlayer.bind(@))
		$(window).resize(@_updateGameSize.bind(@))

		@room = new Room(10, 10, 5)
		@scene.add(@room.object)
		@scene.add(new THREE.AxisHelper(200))

		@player = new Player()
		@player.moveTo(@room.tiles[4][4])
		@scene.add(@player.object)

		console.log('Game launched!')

	run: ->
		requestAnimationFrame(@run.bind(@))
		TWEEN.update()
		@mesh.rotation.x += 0.005
		@mesh.rotation.y += 0.01

		@_handleTileIntersection()
		@renderer.render(@scene, @camera)

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

		for intersect in intersects
			geom = intersect.object.geometry
			isTile = geom.width is Const.tileSize and geom.faces.length is 2
			return intersect.object if isTile

	_getMousePosition: (event) ->
		event.preventDefault()
		@mousePos ?= new THREE.Vector3(0, 0, 0.5);
		@mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

	_movePlayer: (event) ->
		event.preventDefault()
		intersectedTile = @_getIntersectedTile()
		@player.moveTo(intersectedTile)

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
		$('body').append(@renderer.domElement)

	_setupScene: ->
		@scene = new THREE.Scene()

		width = window.innerWidth / 2
		height = window.innerHeight / 2
		@camera = new THREE.OrthographicCamera(-width, width, height, -height, -500, 1000)
		@camera.position = new THREE.Vector3(100, 100, 100)
		@camera.scale.set(0.5, 0.5, 0.5)
		@camera.lookAt(Const.origin)
		@camera.position.x /= 2
		@camera.position.z /= 2

$ ->
	game = new Game()
	game.run()