request = require 'request'
cheerio = require 'cheerio'

fetch_players_list = (callback) ->
  request 'http://espn.go.com/golf/players', (error, response, body) ->
  	$ = cheerio.load(body)
  	player = []

  	$('#my-players-table table tr td a').map (i,link) ->
  		player.push { name: $(link).text() }
  	console.log player.length

fetch_players_list()