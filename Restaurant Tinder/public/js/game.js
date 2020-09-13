"use strict";

const queryString = window.location.search;
const urlParams = new URLSearchParams(queryString);
const gameID = urlParams.get("gameid");
if (gameID == null) {
  window.location.assign("https://" + window.location.hostname);
}
var currentCandidate = {};

document.getElementById("btnReject").addEventListener("click", rejectCandidate);
document.getElementById("btnHeart").addEventListener("click", acceptCandidate);
let waitingDiv = document.getElementById("waitingDiv");
let waitingMsg = document.getElementById("waitingMessage");
let roundNum = document.getElementById("roundNum");

let rImage = document.getElementById("restaurantImg");
let rName = document.getElementById("restaurantName");
let rCost = document.getElementById("restaurantCost");
let rType = document.getElementById("restaurantType");
let rRating = document.getElementById("restaurantRating");
let rAddress = document.getElementById("restaurantAddress");
let rReviews = document.getElementById("reviewsLink");

var socket = io("https://rambunctious-fluoridated-card.glitch.me/");
socket.on("connect", function() {
  console.log("Connected to Restaurant Tinder server.");
  socket.emit("joingame", gameID);
});
socket.on("servernotif", function(msg) {
  console.log("[SERVER] " + msg);
});
socket.on("servererr", function(msg) {
  alert(msg);
});
socket.on("disconnect", function() {
  console.log("Disconnected from Restaurant Tinder server");
  socket.emit("disconnect", gameID);
});
socket.on("gamestart", function() {
  waitingDiv.className = "hideDiv";
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
    gameid: gameID,
    restID: currentCandidate.restID,
    vote: 0
  });
}

function acceptCandidate() {
  socket.emit("playervote", {
    gameid: gameID,
    restID: currentCandidate.restID,
    vote: 1
  });
}