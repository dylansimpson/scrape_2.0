var 
	request = require("request"),
	cheerio = require("cheerio");
		
	request('http://espn.go.com/golf/players', function (error, response, body) {
		if (!error && response.statusCode == 200) {
			var $ = cheerio.load(body);
			var urls = [];
			var names = [];
			var year = ['/year/2000/','/year/2001/','/year/2002/','/year/2003/','/year/2004/','/year/2005/','/year/2006/','/year/2007/','/year/2008/','/year/2009/','/year/2010/','/year/2011/','/year/2012/','/year/2013/'];
	 		var last_marker;
			var url;
			var temp_url;
			var finalized_url;
			var number_of_players;

			names = ($('#my-players-table table tr td a').map(function(i,link) { return $(link).text();}))

			// console.log(names[44]);

			number_of_players = names.length;

			urls = $('#my-players-table table tr td a').map(function(i,link) { return $(link).attr('href');})

			// loop here to generate all the play + year and then send it
			
	 		while (number_of_players>-1)
	 		{

	 		url = names[number_of_players]//Current url from //'http://espn.go.com/golf/player/_/id/308/phil-mickelson';
	 		last_marker = url.lastIndexOf("/");
			temp_url = url.substr(0,last_marker)+year[current_year]+ url.substr(last_marker+1);
			finalized_url  = temp_url.substr(0,30)+'/scorecards'+temp_url.substr(30,(last_marker+1));
			console.log(finalized_url)
			}
		}
	})

	request('http://espn.go.com/golf/player/scorecards/_/id/462/year/2004/tiger-woods', function (error, response, body) {
	if (!error && response.statusCode == 200) {
		var tournament;
		var url;
		var row;
		var $ = cheerio.load(body);

		tournament = $('.js-goto > select:nth-child(2) option').map(function(i,link) { return $(link).text();})

		url = $('.js-goto > select:nth-child(2) option').map(function(i,link) { return $(link).attr('value');})

		//console.log(tournament[4])
		//console.log(url[4])

		//////////////////////////////////////////////////////
		// Code to take all of the scores
		//rounds = console.log($('[id|=round]').text())
		console.log($('tr.oddrow').text())

	}	
})
