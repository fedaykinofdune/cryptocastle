express = require('express')
http    = require('http')
io      = require('socket.io')

app = express()
server = http.createServer(app)
io = io.listen(server)
server.listen(process.env.PORT or 9393)

app.set('view engine', 'jade')
app.use(express.static(__dirname + '/public'))
app.get('/', (req, res) ->
    res.render('index')
)

io.sockets.on('connection', (socket) ->
    playerJSON = JSON.stringify(
        speed: (Math.random() / 4).toFixed(2)
        color: Math.random() * 0xffffff
    )

    socket.emit('player', playerJSON)

    console.log('websocket connection open')

    socket.on('close', ->
        console.log('websocket connection close')
    )
)