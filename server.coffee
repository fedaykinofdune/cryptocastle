WebSocketServer = require('ws').Server
express         = require('express')
http            = require('http')
_               = require('underscore')

app = express()
app.set('view engine', 'jade')
app.use(express.static(__dirname + '/public'))
app.get('/', (req, res) ->
    res.render('index')
)

port = process.env.PORT or 9393
server = http.createServer(app)
server.listen(port)

wss = new WebSocketServer(server: server)
wss.on('connection', (ws) ->
    playerJSON = JSON.stringify(
        player:
            speed: (Math.random() / 4).toFixed(2)
            color: Math.random() * 0xffffff
    )

    ws.send(playerJSON)

    console.log('websocket connection open')

    ws.on('close', ->
        console.log('websocket connection close')
    )
)