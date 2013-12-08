THREE = require('three')
$     = require('jquery')

Room  = require('./room')
Const = require('./constants')

class Game
	constructor: ->
		@mousePos = null
		@prevIntersectedMesh = null

		@_setupRenderer()
		@_setupScene()

		# Add a test mesh.
		geometry = new THREE.CubeGeometry(50, 50, 50)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@mesh.position.y = 100
		@scene.add(@mesh)

		$(document).mousemove(@_getMousePosition.bind(@))
		$(window).resize(@_updateGameSize.bind(@))

		@room = new Room(10, 10, 5)
		@scene.add(@room.object)
		@scene.add(new THREE.AxisHelper(200))

		console.log('Game launched!')

	run: ->
		requestAnimationFrame(@run.bind(@))
		@mesh.rotation.x += 0.005
		@mesh.rotation.y += 0.01

		@_handleTileIntersection()
		@renderer.render(@scene, @camera)

	_handleTileIntersection: ->
		return unless @mousePos

		intersectedMesh = @_getIntersectedTile()
		unless intersectedMesh
			return @prevIntersectedMesh?.visible = false

		if intersectedMesh isnt @prevIntersectedMesh
			intersectedMesh.visible = true
			@prevIntersectedMesh?.visible = false
			@prevIntersectedMesh = intersectedMesh

	_getIntersectedTile: ->
		ray = @projector.pickingRay(@mousePos.clone(), @camera)
		intersects = ray.intersectObjects(@scene.children, true)

		for intersect in intersects
			isTile = intersect.object.geometry.width is Const.tileSize
			return intersect.object if isTile

	_getMousePosition: (event) ->
		event.preventDefault()
		@mousePos ?= new THREE.Vector3(0, 0, 0.5);
		@mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

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