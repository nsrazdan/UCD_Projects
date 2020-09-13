"use strict";

document.getElementById("btnJoin").addEventListener("click", function(){
  let inputValue = document.getElementById("codeInput").value;
  if (inputValue == "") {
    alert("Please enter a valid code.");
  } else {
  inputValue = inputValue.toUpperCase();
  //Redirect users to the appropriate game page.
  window.location.assign("https://" + window.location.hostname + "/game.html?gameid=" + inputValue);
  }
});