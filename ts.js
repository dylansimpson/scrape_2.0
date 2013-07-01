var 
	request = require("request"),
	cheerio = require("cheerio");

	request('http://www.tennisabstract.com/cgi-bin/leaders.cgi', function (error, response, body) {
		if (!error && response.statusCode == 200) {
			var tournament;
			var $ = cheerio.load(body);

			tournament = $('html body div#main table#maintable tbody tr td#stats.stats table#matches.tablesorter').map(function(i,link) { return $(link).text();})

			console.log($.text());

		}	
	})
