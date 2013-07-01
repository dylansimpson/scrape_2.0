var 
	request = require("request"),
	cheerio = require("cheerio");
	
	request('http://espn.go.com/golf/player/scorecards/_/id/462/year/2004/tiger-woods', function (error, response, body) {
		if (!error && response.statusCode == 200) {
			var tournament;
			var url;
			var row;
			var $ = cheerio.load(body);

			tournament = $('.js-goto > select:nth-child(2) option').map(function(i,link) { return $(link).text();})

			url = $('.js-goto > select:nth-child(2) option').map(function(i,link) { return $(link).attr('value');})

			console.log(tournament[0])
			console.log(url[4])

			//////////////////////////////////////////////////////
			// Code to take all of the scores

			//rounds = console.log($('[id|=round]').text())
			console.log($('tr.oddrow').text())
			
			//console.log($('tr.oddrow').text())

			//row = $('/html/body/div[5]/div[3]/div/div[2]/div[5]/div/div/div[2]/div[3]/div/div/table/tbody/tr[4]')

			//All cards: /html/body/div[2]/div[2]/div/div[2]/div[5]/div/div/div[2]
			//First card: //*[@id="round-4-462"]
			//First card rountr.oddrowd: /html/body/div[2]/div[2]/div/div[2]/div[5]/div/div/div[2]/div[3]/div/div/table/tbody/tr[4]

		}	
	})