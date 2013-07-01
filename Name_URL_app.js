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

			names = ($('#my-players-table table tr td a').map(function(i,link) { return $(link).text();}))

			urls = $('#my-players-table table tr td a').map(function(i,link) { return $(link).attr('href');})

			// loop here to generate all the play + year and then send it
			
	 		url = //Current url from fruntion one //'http://espn.go.com/golf/player/_/id/308/phil-mickelson';
	 		last_marker = url.lastIndexOf("/");
			temp_url = url.substr(0,last_marker)+year[12]+ url.substr(last_marker+1);
			finalized_url  = temp_url.substr(0,30)+'/scorecards'+temp_url.substr(30,(last_marker+1));
			console.log(finalized_url)
		}
	})