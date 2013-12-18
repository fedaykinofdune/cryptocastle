THREE = require('three')

Prop  = require('./prop')
Const = require('./constants')

class DiceTable extends Prop
	constructor: ->
		@layout = [[true, true]]

		geometry = new THREE.CubeGeometry(Const.tileSize * @yGridSize(), Const.tileSize / 2, Const.tileSize * @xGridSize())
		material = new THREE.MeshLambertMaterial(color: 0xcccccc)
		@object = new THREE.Mesh(geometry, material)

		super()

class Chair extends Prop
	constructor: ->
		@layout = [[true]]
		
		geometry = new THREE.CubeGeometry(Const.tileSize * @yGridSize(), Const.tileSize / 2, Const.tileSize * @xGridSize())
		material = new THREE.MeshLambertMaterial(color: 0xcccccc)
		@object = new THREE.Mesh(geometry, material)

		super()

exports.DiceTable = DiceTable
exports.Chair = Chair