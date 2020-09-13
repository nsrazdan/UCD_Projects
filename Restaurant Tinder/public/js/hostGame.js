"use strict";
var keywords = [];
var gameid = "";
document.getElementById("btnInvite").addEventListener("click", showInviteInfo);
document.getElementById("btnStart").addEventListener("click", startGame);
document.getElementById("btnKeyword").addEventListener("click", addKeyword);
let inviteLinkParent = document.getElementById("inviteLinkParent");
let inviteCodes = document.getElementsByClassName("inviteCode");
let inviteLink = document.getElementById("inviteLink");

let locationField = document.getElementById("locationSearchField");
let keywordField = document.getElementById("keywordSearchField");

let keywordsTable = document.getElementById("keywordsTable");


var socket = io('https://rambunctious-fluoridated-card.glitch.me/');
socket.on('connect', function(){
  console.log('Connected to Restaurant Tinder server.');
  socket.emit('creategame');
});
socket.on('gameid', function(data) {
  for (var i = 0; i < inviteCodes.length; i++) {
    inviteCodes[i].innerText = data;
  };
  let newHREF = "https://rambunctious-fluoridated-card.glitch.me/game.html?gameid=" + data;
  inviteLink.innerText = newHREF;
  gameid = data;
  console.log("[SERVER]: Game ID assigned: " + gameid);
});
socket.on('servernotif', function(msg) {
  console.log('[SERVER] ' + msg);
});
socket.on('servererr', function(msg) {
  alert(msg);
});
socket.on("disconnect", function() {
  console.log("Disconnected from Restaurant Tinder server");
  socket.emit("disconnect", gameid);
});


function showInviteInfo() {
  let inviteDisplay = inviteLinkParent.style.display;
  if (inviteDisplay == "" || inviteDisplay == "none") {
    inviteLinkParent.style.display = "block";
  }
}

function addKeyword() {
  let newKeyword = keywordField.value;
  if (newKeyword !== null && newKeyword.match(/^ *$/) === null) {
    keywords.push(newKeyword.trim());
    keywordField.value = "";
    addKeywordRow(newKeyword);
    console.log(keywords);
  }
};

function addKeywordRow(newKeyword) {
  if (newKeyword !== null) {
    var newRow = keywordsTable.insertRow(keywordsTable.rows.length);
    newRow.className += "keyTR"
    newRow.value = newKeyword;
    var keyCell = newRow.insertCell(0);
    var btnCell = newRow.insertCell(1);
    keyCell.className += "keyTD keyTDname";
    keyCell.innerHTML = "<span>" + newKeyword + "</span>";
    btnCell.className += "keyTD keyTDbtn";
    btnCell.innerHTML = "<span>Remove<span>";
    btnCell.value = newKeyword;
    btnCell.addEventListener('click', function() {
      removeKeyword(btnCell);
    });
  }
};

function removeKeyword(buttonElement) {
  let buttonValue = buttonElement.value;
  let rows = document.getElementsByClassName("keyTR");
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].value == buttonValue) {
      rows[i].remove();
      let keywordIndex = keywords.indexOf(buttonValue);
      keywords.splice(keywordIndex, 1);
      console.log(keywords);
    }
  }
};


function startGame() {
  let locationValue = locationField.value;
  if (locationValue !== null && locationValue.match(/^ *$/) === null) {
    socket.emit('startgame', {
      location: locationValue,
      keywords: keywords
    });
  } else {
    alert("Please enter a location!");
  }
}


/* Gameplay Functionality */
var currentCandidate = {};

document.getElementById("btnReject").addEventListener("click", rejectCandidate);
document.getElementById("btnHeart").addEventListener("click", acceptCandidate);
let waitingDiv = document.getElementById("waitingDiv");
let waitingMsg = document.getElementById("waitingMessage");
let header = document.getElementById("header");

let hostGameControls = document.getElementById("hostGameControls");
let session =  document.getElementById("sessionParent");
let roundNum = document.getElementById("roundNum");

let rImage = document.getElementById("restaurantImg");
let rName = document.getElementById("restaurantName");
let rCost = document.getElementById("restaurantCost");
let rType = document.getElementById("restaurantType");
let rRating = document.getElementById("restaurantRating");
let rAddress = document.getElementById("restaurantAddress");
let rReviews = document.getElementById("reviewsLink");

socket.on("gamestart", function() {
  hostGameControls.className = "hideControls";
  session.className = "";
  waitingDiv.className = "hideDiv";
  header.className = "hideDiv";
});
socket.on("newcandidate", function(data) {
  waitingDiv.className = "hideDiv";
  rImage.style.backgroundImage = "url(" + data.imageURL + ")";
  rName.innerText = data.name;
  rCost.innerText = data.price;
  rType.innerText = data.category;
  styleRating(data.rating);
  rAddress.innerText = data.address;
  rReviews.href = data.restURL;
  currentCandidate = data;
  console.log("RESTAURANT: ", data);
});
socket.on("updatecurrentvotes", function(data) {
  waitingMsg.innerText =
    "Waiting for other players to vote (" +
    data.currVotes +
    "/" +
    data.numPlayers +
    " voted) ...";
});
socket.on("roundupdate", function(data) {
  roundNum.innerText = data;
});
socket.on("restchosen", function(data) {
  let queryString = "?";
  queryString += "name=" + encodeURIComponent(data.name);
  queryString += "&price=" + encodeURIComponent(data.price);
  queryString += "&category=" + encodeURIComponent(data.category);
  queryString += "&rating=" + encodeURIComponent(data.rating);
  queryString += "&address=" + encodeURIComponent(data.address);
  queryString += "&image=" + encodeURIComponent(data.imageURL);
  queryString += "&url=" + encodeURIComponent(data.restURL);
  window.location.assign(
    "https://" + window.location.hostname + "/result.html" + queryString
  );
});
socket.on("votereceived", function() {
  waitingDiv.className = "";
  waitingMsg.innerText = "Waiting for other players to vote...";
});

function styleRating(rating) {
  let pRating;
  if (typeof(rating) == "string") {
    pRating = parseFloat(rating);
  } else {
    pRating = rating;
  }
  let roundRating = Math.floor(pRating);
  let newString = "";
  for (var i=0; i < roundRating; i++) {
    newString += '\u2605';
  }
  for (var i=0; i < (5 - roundRating); i++) {
    newString += '\u2606';
  }
  rRating.innerText = newString;
};

function rejectCandidate() {
  socket.emit("playervote", {
    gameid: gameid,
    restID: currentCandidate.restID,
    vote: 0
  });
};

function acceptCandidate() {
  socket.emit("playervote", {
    gameid: gameid,
    restID: currentCandidate.restID,
    vote: 1
  });
};