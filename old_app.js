 var 
	Parser = require("./parser"),
	Loader = require("./loader");

var _finished = function(){
	console.log("Done parsing all the things.");
	process.exit(1);
};


Loader.load("http://www.players.com/listofplayers", function(err, players){
	if(err) throw err;

	var len = players.length, 
	doneParsing = function(err, data){
		if(err) throw err;
		console.log(data);
		return --len || _finished();
		};

	for(var i in players) {
		Parser.parse("URL of Player from loader", doneParsing);		
	}
});
