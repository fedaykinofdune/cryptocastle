THREE = require('three')

Const = require('./constants')

module.exports = class Room
	constructor: (@xTiles, @yTiles, @zTiles) ->
		console.log('Room code!')

		sizeX = Const.tileSize * @xTiles
		sizeY = Const.tileSize * @yTiles
		sizeZ = Const.tileSize * @zTiles

		# Build the isometric room.
		material = new THREE.MeshNormalMaterial()
		material.side = THREE.DoubleSide

		floor = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeY), material)
		leftWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeY, sizeZ), material)
		rightWall = new THREE.Mesh(new THREE.PlaneGeometry(sizeX, sizeZ), material)

		floor.rotation.x = Math.PI / 2
		leftWall.rotation.y = Math.PI / 2
		leftWall.rotation.z = Math.PI / 2
		leftWall.position = new THREE.Vector3(-sizeX / 2, 0, -sizeZ / 2)
		rightWall.rotation.x = Math.PI / 2
		rightWall.rotation.y = Math.PI
		rightWall.position = new THREE.Vector3(0, -sizeY / 2, -sizeZ / 2)

		floor.add(leftWall)
		floor.add(rightWall)

		@object = floor
		@object
