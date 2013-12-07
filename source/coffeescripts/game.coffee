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
		mousePos = new THREE.Vector3(@mousePos.x, @mousePos.y, 1)
		@projector.unprojectVector(mousePos, @camera)
		@raycaster.set(@camera.position, mousePos.sub(@camera.position).normalize())
		intersects = @raycaster.intersectObjects(@scene.children, true)

		for intersect in intersects
			isTile = intersect.object.geometry.width is Const.tileSize
			return intersect.object if isTile

	_getMousePosition: (event) ->
		event.preventDefault()
		@mousePos ?= {}
		@mousePos.x = (event.clientX / window.innerWidth) * 2 - 1
		@mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1

	_updateGameSize: ->
		@camera.aspect = window.innerWidth / window.innerHeight
		@camera.updateProjectionMatrix()
		@renderer.setSize(window.innerWidth, window.innerHeight) 

	_setupRenderer: ->
		@projector = new THREE.Projector()
		@raycaster = new THREE.Raycaster()

		@renderer = new THREE.WebGLRenderer()
		@renderer.setSize(window.innerWidth, window.innerHeight)
		$('body').append(@renderer.domElement)

	_setupScene: ->
		@scene = new THREE.Scene()
		@camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 1000)
		@camera.position = new THREE.Vector3(150, 150, 150)
		@camera.lookAt(Const.origin)

$ ->
	game = new Game()
	game.run()