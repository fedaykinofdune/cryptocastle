THREE = require('three')
$     = require('jquery')

Room  = require('./room')
Const = require('./constants')

class Game
	constructor: ->
		@_setupRenderer()
		@_setupScene()

		# Add a test mesh.
		geometry = new THREE.CubeGeometry(200, 200, 200)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@mesh.scale.multiplyScalar(1 / 4)
		@mesh.position.y = 100
		@scene.add(@mesh)

		$(window).resize(@_updateGameSize.bind(@))

		room = new Room(10, 10, 5)
		@scene.add(room.object)

		@scene.add(new THREE.AxisHelper(200))

		console.log('Game launched!')

	run: ->
		requestAnimationFrame(@run.bind(@));
		@mesh.rotation.x += 0.005;
		@mesh.rotation.y += 0.01;
		@renderer.render(@scene, @camera);	

	_updateGameSize: ->
		@camera.aspect = window.innerWidth / window.innerHeight
		@camera.updateProjectionMatrix()
		@renderer.setSize(window.innerWidth, window.innerHeight) 

	_setupRenderer: ->
		@renderer = new THREE.WebGLRenderer()
		@renderer.setSize(window.innerWidth, window.innerHeight)
		$('body').append(@renderer.domElement)

	_setupScene: ->
		@scene = new THREE.Scene()
		@camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 1000)
		@camera.position.x = 150
		@camera.position.y = 150
		@camera.position.z = 150
		@camera.lookAt(Const.origin)

$ ->
	game = new Game()
	game.run()