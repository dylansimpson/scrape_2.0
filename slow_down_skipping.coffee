request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
fs = require 'fs'
{exec} = require 'child_process'
_ = require 'underscore'
util = require 'util'

fetch_players_list = (callback) ->
  request 'http://espn.go.com/golf/players', (error, response, body) ->
    $ = cheerio.load(body)
    players = []

    $('#my-players-table table tr td a').map (i,link) ->
      urls = []
      template_url = $(link).attr('href')
      for year in [2003..2012]
        urls.push year_url(template_url, year)
      players.push { name: $(link).text(), urls: urls }

    players = players[0..400]

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
    tournaments
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
    temp_course = if year == '0000' then '' else $('.mod-player-stats h3').next().text()
    course = temp_course.replace(/,/g,"-")

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

    callback null, { url: url, name: name, year: year, rounds: rounds, course: course}

compact_array = (list) ->
  _.reject list, (t) -> t.length == 0

write_player_data = (name, results, callback) ->
  console.log "Writing player #{name}"
  fs.exists "players/#{name}.csv", (exists) =>
    console.log exists
    if exists == true
      console.log "Skipped"
      callback null
    else
      fs.appendFile("players/#{name}.csv", "URL,Tournament,Date,Round,Courses,Specific Course,Year,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType,Hole,Yards,Par,Score,ShotType, ,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType,ShotType, \n")
      for card in results
        for round in card.rounds
          edited_round = round.round.replace(",","-").replace("Scorecard - ","").split("- ")
          specific_course = if edited_round.length > 1 then edited_round[1] else ''
          edited_name = card.name.split(" - ")
          event_date = edited_name[1].substring(2,edited_name[1].length-1);

          row = "#{card.url},#{edited_name[0]},#{event_date},#{edited_round[0]},#{card.course},#{specific_course},#{card.year}, "
          i = 1
          for hole in round.holes
            cal_shot = calculated_shot(hole.par, hole.score)
            row += "#{i}, #{hole.yards}, #{hole.par}, #{hole.score}, #{cal_shot}, "
            i += 1
          row += ' ,'
          for hole in round.holes
            cal_shot_single = calculated_shot(hole.par, hole.score)
            row += " #{cal_shot_single},"
          row += "\n"

          fs.appendFile("players/#{name}.csv", row)
        callback null



calculated_shot = (par, score) =>
  if par == '3'
    switch score
      when '1' then 21
      when '2' then 22
      when '3' then 23
      when '4' then 24
      when '5' then 25
      else 26    
  else if par == '4'
    switch score
      when '1' then 27
      when '2' then 28
      when '3' then 29
      when '4' then 30
      when '5' then 31
      when '6' then 32
      else 33
  else if par == '5'
    switch score
      when '1' then 34
      when '2' then 35
      when '3' then 36
      when '4' then 37
      when '5' then 38
      when '6' then 39
      when '7' then 40
      else 41
  else 0

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
    #console.log "Done"