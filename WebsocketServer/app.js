
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');
var app = express();
var registerDeviceCount = 0;

// websocket
var sockjs = require('sockjs');
var wbsc = sockjs.createServer();
var connections = [];

// all environments
app.set('port', process.env.PORT || 3001);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);
app.get('/users', user.list);
app.get('/register', function(req, res) {
				 	res.writeHead(501, {"Content-Type": "application/json"});
				  	res.end( JSON.stringify({devId: registerDeviceCount}) );					
					registerDeviceCount++;					
				});

var server = http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});


// websocket events
wbsc.on('connection', function(conn) {
	console.log('Got connection' + conn.address.address);
	connections.push(conn);

	conn.on('data', function(message) {
		// send message to all connected clients
		for(var i=0; i<connections.length; i++) {
			connections[i].write(message);
		}
	});

	conn.on('close', function() {
		connections.splice(connections.indexOf(conn), 1); // remove the connection
		console.log('Lost connection');
	});
});

wbsc.installHandlers(server, {prefix:'/wbsc'});
