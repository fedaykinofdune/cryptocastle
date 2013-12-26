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

# When the server first boots up, it loads a room. For now it just creates a
# sandbox one.
room = new Room(10, 5, 10)
table = new Props.DiceTable()
room.placeProp(table, 4, 1)

connections = {}
io.sockets.on('connection', (socket) ->
    console.log('websocket connection open')
    
    socket.on('entityMoveRequest', (data) ->
        socket.emit('entityMoveResponse', success: true)
    )
    socket.on('close', ->
        console.log('websocket connection close')
        delete _connections[socket.id]
    )
    connections[socket.id] = socket

    player = new Player(room)
    room.placeProp(player, 9, 5)

    socket.emit('init', room.toJSON())
)