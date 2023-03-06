var gcard = {};
var container = document.getElementById("container");
var holeInfo = {};
var scores = {};
var savedScores = {};

gcard.Open = function() {
	var distance = document.getElementById("distance");
	var par = document.getElementById("par");
	var distanceTotal = 0;
	var parTotal = 0;
	var scoreTotal = 0;
	distance.innerHTML = "<th>Meters</th>";
	par.innerHTML = "<th>Par</th>";
	for(i = 0; i < 9; i++){
		distance.innerHTML = distance.innerHTML + "<th>" + Math.round(holeInfo[i].Distance * 10) / 10 + "</th>"
		distanceTotal = distanceTotal + holeInfo[i].Distance;
		par.innerHTML = par.innerHTML + "<th>" + holeInfo[i].Par + "</th>"
		parTotal = parTotal + holeInfo[i].Par;
	}
	distance.innerHTML = distance.innerHTML + "<th>" + Math.round(distanceTotal * 10) / 10 + "</th>"
	par.innerHTML = par.innerHTML + "<th>" + parTotal + "</th>"
	for(i = 0; i < scores.length; i++){
		elementId = "p1s" + (i + 1);
		document.getElementById(elementId).value = scores[i];
	}
	tally("p1s");
	if(savedScores != null) {
		for(i = 0; i < savedScores.length; i++){
			elementId = "p2s" + (i + 1);
			document.getElementById(elementId).value = savedScores[i];
		}
		tally("p2s");
	}
	container.style.visibility = "visible";
	container.style.opacity = "1";
}

gcard.Close = function() {
	container.style.visibility = "hidden";
	container.style.opacity = "0";
	container.style.transition = "visibility 0s 0.5s, opacity 0.5s linear";
	$.post(`https://${GetParentResourceName()}/close`);
	gcard.Clear();
}

gcard.Save = function() {
	container.style.visibility = "hidden";
	container.style.opacity = "0";
	container.style.transition = "visibility 0s 0.5s, opacity 0.5s linear";
	$.post(`https://${GetParentResourceName()}/save`);
	gcard.Clear();
}

gcard.Clear = function() {
	for(i = 1; i < 10; i++){
			elementId1 = "p1s" + (i);
			elementId2 = "p2s" + (i);
			document.getElementById(elementId1).value = ' ';
			document.getElementById(elementId2).value = ' ';
		}
		tally("p1s");
		tally("p2s");
}

$(document).ready(function(){
	window.addEventListener('message', function(event) {
		switch(event.data.action) {
			case "open":
				holeInfo = event.data.holes;
				scores = event.data.scores;
				savedScores = event.data.savedscores;
				gcard.Open();
				break;
			case "close":
				gcard.Close();
				break;
		}
	})
});

$(document).on('keydown', function() {
	switch(event.keyCode) {
		case 27: // ESC
			gcard.Close();
			break;
	}
});

function tally(name){
	var arr = document.getElementsByName(name);
	var tot = 0;
	for(i = 0; i < 9; i++){
		if(Number(arr[i].value)) tot += Number(arr[i].value);
	}
	if (tot == 0) {
		tot = ' ';
	}
	document.getElementById(name).value = tot;
}

function reset() {
	for (j = 1; j < 5; j++){
		for (k = 1; k < 10; k++) {
			document.getElementById('p' + j + 's' + k).value = ' ';
		}
		document.getElementById('player' + j).value = '';
		tally('p' + j + 's');
	}
}