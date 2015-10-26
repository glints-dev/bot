var express = require('express');
var port = process.env.PORT || 3000;
var app = express();
var http = require('http');
var server = http.createServer(app);

app.get('/', function(request, response) {
    response.sendFile(__dirname + '/index.html');
}).listen(port);
