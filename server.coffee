WebSocketServer = require('ws').Server
express         = require('express')
http            = require('http')

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
  intervalID = setInterval((->
    ws.send(JSON.stringify(new Date()), ->)
  ), 1000)

  console.log('websocket connection open')

  ws.on('close', ->
    console.log('websocket connection close')
    clearInterval(intervalID)
  )
)