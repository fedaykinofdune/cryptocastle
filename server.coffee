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
    _connections: {}
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

    _broadcast: ->
        for id, connection of @_connections
            connection.socket.emit(arguments...)

    _removeProp: (prop) ->
        @_room.removeProp(prop)
        @_broadcast('removeProp', id: prop.id)
        delete @_props[prop.id]

    _placeProp: (prop, x, y) ->
        prop.id = @_propID++
        @_props[prop.id] = prop
        @_room.placeProp(prop, x, y)
        @_broadcast('createProp', x: x, y: y, data: prop.toJSON())
        @_propID += 1

    _handleSocketConnection: (socket) ->
        socket.on('movePropRequest', (data) =>
            prop = @_props[data.id]
            tile = @_room.tiles[data.x][data.y]
            return unless prop and tile
            return unless @_room.propFitsOn(prop, tile)

            @_room.removeProp(prop)
            @_room.placeProp(prop, tile)
            @_broadcast('moveProp', data)
        )
        socket.on('disconnect', => 
            @_removeProp(@_connections[socket.id].player)
            delete @_connections[socket.id]
        )

        # Send out the initial game configuration.
        socket.emit('init', @_room.toJSON())

        # Create the new player and broadcast him to everyone but the current
        # connection.
        player = new Player(@_room)
        @_placeProp(player, 9, 5)

        # Send the new player to the current connection as the current player.
        playerJSON = player.toJSON()
        playerJSON.currentPlayer = true
        socket.emit('createProp', x: player.tile.xGrid, y: player.tile.yGrid, data: playerJSON)

        @_connections[socket.id] = socket: socket, player: player

gameServer = new GameServer()