express = require('express')
http    = require('http')
io      = require('socket.io')

Room    = require('./source/coffeescripts/room')
Player  = require('./source/coffeescripts/player')
Props   = require('./source/coffeescripts/props')

app = express()
server = http.createServer(app)
io = io.listen(server)
server.listen(process.env.PORT or 9393)

app.set('view engine', 'jade')
app.use(express.static(__dirname + '/public'))
app.get('/', (req, res) ->
    res.render('index')
)

# The back-end counterpart to Game. Has a similar API but handles broadcasting
# socket information to connections.
class GameServer
    _players: {}
    _props: {}
    _propID: 0
    _room: null

    constructor: ->
        # When the server first boots up, it loads a room. For now it just
        # creates a sandbox one.
        @_room = new Room(10, 5, 10)

        table = new Props.DiceTable()
        @_placeProp(table, 4, 1)

        io.sockets.on('connection', @_handleSocketConnection.bind(@))

    _removeProp: (prop) ->
        @_room.removeProp(prop)
        delete @_props[prop.id]
        io.sockets.emit('removeProp', id: prop.id)

    _placeProp: (prop, x, y, options = {}) ->
        prop.id = @_propID
        @_propID += 1
        @_props[prop.id] = prop
        @_room.placeProp(prop, x, y)

        unless options.silent
            io.sockets.emit('createProp', x: x, y: y, data: prop.toJSON())   

    _handleSocketConnection: (socket) ->
        socket.on('movePropRequest', (data) =>
            prop = @_props[data.id]
            tile = @_room.tiles[data.x][data.y]
            return unless prop and tile
            return unless @_room.propFitsOn(prop, tile)

            @_room.removeProp(prop)
            @_room.placeProp(prop, tile)
            io.sockets.emit('moveProp', data)
        )
        socket.on('disconnect', => 
            @_removeProp(@_players[socket.id])
            delete @_players[socket.id]
        )

        # Send out the initial game configuration.
        socket.emit('init', @_room.toJSON())

        # Create the new player and broadcast him to everyone but the current
        # connection.
        player = new Player(@_room)
        @_placeProp(player, 9, 5, silent: true)
        message = x: player.tile.xGrid, y: player.tile.yGrid, data: player.toJSON()
        socket.broadcast.emit('createProp', message)

        # Send the new player to the current connection as the current player.
        message.data.currentPlayer = true
        socket.emit('createProp', message)

        @_players[socket.id] = player

gameServer = new GameServer()