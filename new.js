(function() {
  var async, cheerio, compact_array, exec, fetch_players_list, fetch_scorecard, fetch_scorecards, fetch_tournament_card, fs, request, save_and_open_page, util, write_player_data, year_url, _;

  request = require('request');

  cheerio = require('cheerio');

  async = require('async');

  fs = require('fs');

  exec = require('child_process').exec;

  _ = require('underscore');

  util = require('util');

  save_and_open_page = function(body) {
    var temp_name;
    temp_name = 'tempytempy';
    fs.writeFile("/tmp/" + temp_name + ".html", body);
    return exec("open /tmp/" + temp_name + ".html");
  };

  fetch_players_list = function(callback) {
    return request('http://espn.go.com/golf/players', function(error, response, body) {
      var $, players;
      $ = cheerio.load(body);
      players = [];
      $('#my-players-table table tr td a').map(function(i, link) {
        var template_url, urls, year;
        urls = [];
        template_url = $(link).attr('href');
        for (year = 2000; year <= 2013; year++) {
          urls.push(year_url(template_url, year));
        }
        return players.push({
          name: $(link).text(),
          urls: urls
        });
      });
      return callback(players);
    });
  };

  year_url = function(url, year) {
    var last_marker, temp_url;
    last_marker = url.lastIndexOf('/');
    temp_url = url.substr(0, last_marker) + ("/year/" + year + "/") + url.substr(last_marker + 1);
    return temp_url.substr(0, 30) + '/scorecards' + temp_url.substr(30, last_marker + 1);
  };

  fetch_scorecards = function(player, callback) {
    var urls;
    var _this = this;
    console.log("Fetching scorecard for player " + player.name);
    urls = player.urls.map(function(url) {
      return function(callback) {
        return fetch_scorecard(url, callback);
      };
    });
    return async.series(urls, function(err, results) {
      return callback(null, results);
    });
  };

  fetch_scorecard = function(url, callback) {
    return request(url, function(error, response, body) {
      var $, tournaments;
      $ = cheerio.load(body);
      tournaments = [];
      $('.js-goto > select:nth-child(2) option').map(function(i, link) {
        if ($(link).text() !== 'Select') {
          return tournaments.push({
            tournament: $(link).text(),
            url: $(link).attr('value')
          });
        }
      });
      return callback(null, tournaments);
    });
  };

  fetch_tournament_card = function(name, url, callback) {
    var _this = this;
    return request(url, function(error, response, body) {
      var $, colhead, data, i, k, oddrow, round, rounds, td, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _m, _ref, _ref2, _ref3, _ref4, _ref5;
      $ = cheerio.load(body);
      rounds = [];
      i = 0;
      _ref = $('.active table');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        round = _ref[_i];
        rounds[i] = {};
        rounds[i].round = $(round).find('tr.stathead').text();
        k = 0;
        rounds[i].holes = [];
        _ref2 = $(round).find('tr.colhead');
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          colhead = _ref2[_j];
          _ref3 = $(colhead).find('td').slice(1, 10);
          for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
            td = _ref3[_k];
            data = $(td).html().replace(/<br>/g, "|").split("|");
            rounds[i].holes[k] = {};
            rounds[i].holes[k].yards = data[1];
            rounds[i].holes[k].par = data[2];
            k += 1;
          }
        }
        k = 0;
        _ref4 = $(round).find('tr.oddrow');
        for (_l = 0, _len4 = _ref4.length; _l < _len4; _l++) {
          oddrow = _ref4[_l];
          _ref5 = $(oddrow).find('td').slice(1, 10);
          for (_m = 0, _len5 = _ref5.length; _m < _len5; _m++) {
            td = _ref5[_m];
            rounds[i].holes[k].score = $(td).text();
            k += 1;
          }
        }
        i += 1;
      }
      return callback(null, {
        url: url,
        rounds: rounds
      });
    });
  };

  compact_array = function(list) {
    return _.reject(list, function(t) {
      return t.length === 0;
    });
  };

  write_player_data = function(name, results, callback) {
    var _this = this;
    console.log("Writing player " + name);
    return fs.exists("players/" + name + ".csv", function(exists) {
      var card, hole, i, result, round, row, year, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _results;
      if (exists) fs.unlink("players/" + name + ".csv");
      year = (result = /\/year\/(\d{4})\//.exec(results.url)) ? result[1] : '0000';
      _results = [];
      for (_i = 0, _len = results.length; _i < _len; _i++) {
        card = results[_i];
        _ref = card.rounds;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          round = _ref[_j];
          row = "" + results.url + ", " + year + ", ";
          i = 1;
          _ref2 = round.holes;
          for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
            hole = _ref2[_k];
            row += "" + i + ", " + hole.yards + ", " + hole.par + ", " + hole.score + ", ";
            i += 1;
          }
          row += "\n";
          fs.appendFile("players/" + name + ".csv", row);
        }
        _results.push(callback(null, row));
      }
      return _results;
    });
  };

  fetch_players_list(function(players) {
    var fetchers;
    var _this = this;
    fetchers = players.slice(0, 3).map(function(player) {
      console.log("Player " + player);
      return function(callback) {
        return fetch_scorecards(player, function(error, tournaments) {
          var getters, records, _i, _len;
          tournaments = compact_array(tournaments);
          for (_i = 0, _len = tournaments.length; _i < _len; _i++) {
            records = tournaments[_i];
            getters = records.map(function(tournament) {
              return function(callback) {
                return fetch_tournament_card(tournament.tournament, tournament.url, function(error, cards) {
                  return callback(null, cards);
                });
              };
            });
          }
          return async.series(getters, function(error, results) {
            console.log(results);
            return write_player_data(player.name, results, function(error, results) {
              return callback(null, null);
            });
          });
        });
      };
    });
    return async.series(fetchers, function(err, results) {
      return console.log(results);
    });
  });

}).call(this);
