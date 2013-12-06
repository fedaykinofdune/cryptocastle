THREE = require('three')
$     = require('jquery')

Unit  = require('./unit')
Room  = require('./room')

class Game
	constructor: ->
		@_setupRenderer()
		@_setupScene()

		geometry = new THREE.CubeGeometry(200, 200, 200)
		material = new THREE.MeshBasicMaterial()
		@mesh = new THREE.Mesh(geometry, material)
		@scene.add(@mesh)

		$(window).resize(@_updateGameSize.bind(@))

		unit = new Unit()
		room = new Room()
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
		@camera.position.z = 400

$ ->
	game = new Game()
	game.run()