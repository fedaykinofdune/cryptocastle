THREE = require('three')

module.exports = class Constants
	@gameModes: normal: 0, edit: 1
	@tileSize: 20
	@origin: new THREE.Vector3(0, 0, 0)
	@keys:
		e: 69
		n: 78