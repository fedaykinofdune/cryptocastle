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

socketID2Socket = {}

# When the server first boots up, it loads a room. For now it just creates a
# sandbox one.
room = new Room(10, 5, 10)
player = new Player(room)
table = new Props.DiceTable()
room.placeProp(player, 9, 5)
room.placeProp(table, 4, 1)

io.sockets.on('connection', (socket) ->
    console.log('websocket connection open')

    socketID2Socket[socket.id] = socket
    socket.emit('init', JSON.stringify(room.toJSON()))

    socket.on('entityMoveRequest', (data) ->
        socket.emit('entityMoveResponse', success: true)
    )

    socket.on('close', ->
        console.log('websocket connection close')
        delete _socketID2Socket[socket.id]
    )
)