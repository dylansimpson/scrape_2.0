request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
fs = require 'fs'
{exec} = require 'child_process'
_ = require 'underscore'
util = require 'util'

# save_and_open_page = (body) ->
#   temp_name = 'tempytempy'
#   fs.writeFile "/tmp/#{temp_name}.html", body
#   exec "open /tmp/#{temp_name}.html"

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
  # console.log "Fetch url #{url}"
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
    (callback) => fetch_tournament_card tournament.url, tournament.url, callback

  async.series tournaments, (err, results) ->
    callback null, results

fetch_tournament_card = (name, url, callback) ->
  # console.log "Fetch url #{url}"
  request url, (error, response, body) =>
    $ = cheerio.load body
    rounds = []

    year = if (result = /, (\d{4})$/.exec($('.mod-player-stats h3').text())) then result[1] else '0000'

    i = 0
    for round in $('.active table')
      rounds[i] = {}
      rounds[i].round = $(round).find('tr.stathead').text()

      k = 0
      rounds[i].holes = []
      for colhead in $(round).find('tr.colhead')
        for td in $(colhead).find('td')[1..9]
          data = $(td).html().replace(/<br>/g, "|").split("|")
          rounds[i].holes[k] = {}
          rounds[i].holes[k].yards = data[1]
          rounds[i].holes[k].par = data[2]
          k += 1

      k = 0
      for oddrow in $(round).find('tr.oddrow')
        for td in $(oddrow).find('td')[1..9]
          rounds[i].holes[k].score = $(td).text()
          k += 1

      i += 1

    callback null, { url: url, name: name, year: year, rounds: rounds }

compact_array = (list) ->
  _.reject list, (t) -> t.length == 0

write_player_data = (name, results, callback) ->
  console.log "Writing player #{name}"
  fs.exists "players/#{name}.csv", (exists) =>
    fs.unlink("players/#{name}.csv") if exists
    for card in results
      for round in card.rounds
        row = "#{card.url}, #{card.name}, #{card.year}, "
        i = 1
        for hole in round.holes
          row += "#{i}, #{hole.yards}, #{hole.par}, #{hole.score}, "
          i += 1
        row += "\n"

        fs.appendFile("players/#{name}.csv", row)

      callback null, row

fetch_players_list (players) ->
  fetchers = players.map (player) =>
    _.throttle (callback) =>
      fetch_scorecards player, (error, tournaments) =>
        tournaments = _.flatten compact_array(tournaments)
        getters = tournaments.map (tournament) =>
          (callback) =>
            fetch_tournament_card tournament.tournament, tournament.url, (error, cards) ->
              callback null, cards

        async.series getters, (error, results) =>
          write_player_data player.name, results, (error, results) =>
            callback null, null
      , 100

  async.series fetchers, (err, results) =>
    console.log 'Done'
