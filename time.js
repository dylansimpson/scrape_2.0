var 
	request = require("request"),
	cheerio = require("cheerio");
		
	request('http://espn.go.com/golf/players', function (error, response, body) {
		if (!error && response.statusCode == 200) {
			var $ = cheerio.load(body);

			names = ($('#my-players-table table tr td a').map(function(i,link) { return $(link).text();}))

			number_of_players = names.length;

			console.log(number_of_players)

			}
		})

	1562