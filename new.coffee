request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
fs = require 'fs'
{exec} = require 'child_process'
_ = require 'underscore'

save_and_open_page = (body) ->
  temp_name = 'tempytempy'
  fs.writeFile "/tmp/#{temp_name}.html", body
  exec "open /tmp/#{temp_name}.html"

fetch_players_list = (callback) ->
  request 'http://espn.go.com/golf/players', (error, response, body) ->
    $ = cheerio.load(body)
    players = []

    $('#my-players-table table tr td a').map (i,link) ->
      urls = []
      template_url = $(link).attr('href')
      for year in [2000..2013]
        urls.push year_url(template_url, year)
      players.push { name: $(link).text(), urls: urls }

    callback players

year_url = (url, year) ->
  last_marker = url.lastIndexOf('/')
  temp_url = url.substr(0, last_marker) + "/year/#{year}/" + url.substr(last_marker+1)
  temp_url.substr(0,30) + '/scorecards' + temp_url.substr(30, (last_marker + 1))

fetch_scorecards = (player, callback) ->
  console.log "Fetching scorecard for player #{player.name}"

  urls = player.urls.map (url) =>
    (callback) => fetch_scorecard url, callback

  async.series urls, (err, results) ->
    callback null, results

fetch_scorecard = (url, callback) ->
  request url, (error, response, body) ->
    $ = cheerio.load body
    tournaments = []
    $('.js-goto > select:nth-child(2) option').map (i,link) ->
      unless $(link).text() == 'Select'
        tournaments.push
          tournament: $(link).text(),
          url: $(link).attr('value')

    callback null, tournaments

fetch_tournaments = (tournaments, callback) ->
  records = tournaments.map (tournament) =>
    (callback) => fetch_tournament tournament.url, callback

  async.series tournaments, (err, results) ->
    callback results

fetch_tournament = (name, url, callback) ->
  request url, (error, response, body) ->
    $ = cheerio.load body
    callback null, { name: name, data: $('[id|=round]').text() }

fetch_players_list (players) ->
  players = players.map (player) =>
    (callback) => fetch_scorecards player, callback

  async.series [players[982]], (err, results) ->
    console.log results[0]

    fetch_tournaments results[0], (results) ->
      console.log results
