# Game and HUD have a kind of sketchy relationship together. Our single Game
# object instantiates a single HUD object but passes it a reference to itself.
# The purpose of HUD is to compartmentalize all the UI code. The issue is that
# HUD is deeply connected to Game: interactions with the UI can cause game items
# to be bought or the game mode to change. 

# So lets pretend we have a 'friend' keyword and restrict HUD to using the
# following Game attibutes and absolutely nothing else from Game:
# * Game.mode
# * Game.liftProp

bean  = require('bean')
fs    = require('fs')

Utils = require('./utility')
Const = require('./constants')
Props = require('./props')

module.exports = class HUD
	template: fs.readFileSync("#{__dirname}/templates/ui.html")

	constructor: (@_game) ->
		@el = Utils.createNode(@template)

		@_gameModesFieldset = @el.querySelectorAll('.game-modes')[0]
		@_shopFieldset = @el.querySelectorAll('.shop')[0]

		bean.on(@_gameModesFieldset, 'change', @_handleGameModeChange.bind(@))
		bean.on(@_shopFieldset, 'click', @_handleShopBuy.bind(@))

	enableShop: -> @_shopFieldset.prop('disabled', false)

	disableShop: -> @_shopFieldset.prop('disabled', true)

	setGameModeDisplay: (mode) ->
		radios = @_gameModesFieldset.find('input')
		radios.prop('checked', false)
		radios.eq(mode).prop('checked', true)
		@_game.mode = mode

	_handleGameModeChange: (event) ->
		mode = Const.gameModes[event.target.value]
		@_game.mode = mode if mode?

	_handleShopBuy: (event) ->
		event.preventDefault()
		switch event.target.id
			when 'buy-dice-table'
				@setGameModeDisplay(Const.gameModes.edit)
				@disableShop()
				@_game.liftProp(new Props.DiceTable())
			when 'buy-chair'
				@setGameModeDisplay(Const.gameModes.edit)
				@disableShop()
				@_game.liftProp(new Props.Chair())