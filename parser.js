var Parser = function(){

	var 
		request = require("request"),
		cheerio = require("cheerio");

	var _parse = function(url, done){
		request({
			url: url,
			method: "GET"
		}, function(err, resp, body){
			if(err) throw err;

			console.log(body);

			var $ = cheerio.load(body);

			var yellow_html = _parseHomeScores($);

			var fs = require("fs");

			fs.writeFile("yeller.txt", yellow_html, function(err){
				console.log("done writing");
				return done(err, yellow_html);
			});

			console.log("here");

		});
	}

	var _parseHomeScores = function($){
		console.log("mewo")
		console.log($('.yellow'))

		return $(".yeloow").html();
	};


	return {
		parse: _parse
	};

}();


module.exports = Parser;
