express = require('express')

app = express()
app.set('view engine', 'jade')
app.use(express.static(__dirname + '/public'))

app.get('/', (req, res) ->
  res.render('index')
)

port = process.env.PORT or 9393
app.listen(port)
