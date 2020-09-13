"use strict";

const queryString = window.location.search;
const urlParams = new URLSearchParams(queryString);

let rImage = document.getElementById("restaurantImg");
let rName = document.getElementById("restaurantName");
let rCost = document.getElementById("restaurantCost");
let rType = document.getElementById("restaurantType");
let rRating = document.getElementById("restaurantRating");
let rAddress = document.getElementById("restaurantAddress");
let rReviews = document.getElementById("reviewsLink");

let restName = decodeURIComponent(urlParams.get('name'));
let restPrice = decodeURIComponent(urlParams.get('price'));
let restCategory = decodeURIComponent(urlParams.get('category'));
let restRating = decodeURIComponent(urlParams.get('rating'));
let restAddress = decodeURIComponent(urlParams.get('address'));
let restImage = decodeURIComponent(urlParams.get('image'));
let restURL = decodeURIComponent(urlParams.get('url'));

rImage.style.backgroundImage = "url(" + restImage + ")";
rName.innerText = restName;
rCost.innerText = restPrice;
rType.innerText = restCategory;
styleRating(restRating);
rAddress.innerText = restAddress;
rReviews.href = restURL;


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