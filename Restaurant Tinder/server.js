// Including and initializing packages
const yelp = require('yelp-fusion');
const express = require('express');
const sql = require("sqlite3").verbose();
const FormData = require("form-data");
const multer = require('multer');
const bodyParser = require('body-parser');
const fs = require('fs');
const http = require('http');
const axios = require('axios');
const XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;

// Variables to interact with Yelp
const yelp_api_key = "CI3seAOTh28rugYAdk3PA_VXbycuDCSkBZG8sQiRTjsqsyi49eV5O2sgAJ0HZLgzh2w9qXvKWwnLfu7BHUAdhQ5XAJPXe4l6GXo5j9JpaTvhYCJm_5DYZQRDTjnVXnYx"
const client = yelp.client(yelp_api_key);

/* DATABASE */
// Creating database if file does not exist
// Two tables in database: rtGames and rtRestaurants
// rtGames holds info for currently running game
// rtRestaurants holds info of restaurants for currently running game, as found by Yelp API call
const rtDB = new sql.Database("restaurantTinder.db");
let gamesCMD = " SELECT name FROM sqlite_master WHERE type='table' AND name='rtGames' ";
let restCMD = " SELECT name FROM sqlite_master WHERE type='table' AND name='rtRestaurants' ";
rtDB.get(gamesCMD, function(err, val) {
  if (err) {
    console.log("[DB]: " + err.message);
  }
  if (val === undefined) {
    console.log("[DB]: No games table found - creating one...");
    createGamesTable();
  } else {
    console.log("[DB]: Found games table.");
  }
});
rtDB.get(restCMD, function(err, val) {
  if (err) {
    console.log("[DB]: " + err.message);
  }
  if (val === undefined) {
    console.log("[DB]: No restaurants table found - creating one...");
    createRestaurantsTable();
  } else {
    console.log("[DB]: Found restaurants table.");
  }
});

// Create rtGames table in database if doesn't exist
function createGamesTable() {
  const cRTG = 'CREATE TABLE IF NOT EXISTS rtGames (id TEXT PRIMARY KEY UNIQUE, numPlayers INTEGER, currRound INTEGER)';
  rtDB.run(cRTG, function(err, val) {
    if (err) {
      console.log("[DB]: " + err.message);
    } else {
      console.log("[DB]: Successfully created games table.");
    }
  });
};

// Create rtRestaurants table in database if doesn't exist
function createRestaurantsTable() {
  const cRTR = 'CREATE TABLE IF NOT EXISTS rtRestaurants (entryID INTEGER PRIMARY KEY, restID TEXT, gameID TEXT, posVotes INTEGER, negVotes INTEGER, name TEXT, price TEXT, rating TEXT, address TEXT, imageURL TEXT, category TEXT, restURL TEXT, candidate INTEGER, round INTEGER)';
  rtDB.run(cRTR, function(err, val) {
    if (err) {
      console.log("[DB]: " + err.message);
    } else {
      console.log("[DB]: Successfully created restaurants table.");
    }
  });
};

// Generate random game id to support multiple concurrent games
function getRandID(size) {
   let ret = '';
   let chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   for (let i = 0; i < size; i++) {
      ret += chars.charAt(Math.floor(Math.random() * chars.length));
   }
   return ret;
}

/* SERVER PIPELINE */
// Serve static pages out of public subdirectory
// Serve images out of images subdirectory
// Default GET request gets main html file
const app = express();
app.use(express.static('public'));
app.use("/images",express.static('images'));
app.use(bodyParser.json());
app.get("/", function (request, response) {
  response.sendFile(__dirname + '/public/index.html');
});

/* YELP API */
// Get search results from Yelp for restaurants
function getRestaurantsForGame(categories, location, socket) {  
  var catString = "";
  categories.forEach( (element, index) => {
    let lowercaseElement = element.toLowerCase();
    let formattedElement = lowercaseElement.replace(/\s+/g, '');
    if (categories.length == 1 || index == categories.length-1) {
      catString += formattedElement;
    } else {
      catString += formattedElement + ',';
    }
  });
  axios.get("https://api.yelp.com/v3/businesses/search", {
    params: {
      location: location,
      categories: catString,
      price: "1,2,3,4",
      open_now: true
    },
    headers: {
      'Authorization': `Bearer ${yelp_api_key}`
    }
  }).then(response => {
    storeRestaurantResults(response.data, socket);
  }).catch(err => {
    console.log("[NETWORK]: " + err.message);
    socket.emit('servererr', "Oops, there seems to be an error with your search.");
  });
};

// Store the resultant restaurant data from Yelp in correct format in table
function storeRestaurantResults(data, socket) {
  if (socket.gameid !== undefined && socket.gameid !== '') {
    console.log("[GAME " + socket.gameid + "] Storing restaurants...");
    let restaurants = data.businesses;
    var dbErr = false;
    if (restaurants.length > 0) {
      var restaurantsToSave = [];
      restaurants.forEach(rest => {
        let address = createAddressHelper(rest.location);
        let category = categoryHelper(rest.categories);
        let newRestaurant = {
          restID: rest.id,
          gameID: socket.gameid,
          posVotes: 0,
          negVotes: 0,
          name: rest.name,
          price: rest.price,
          rating: rest.rating,
          address: address,
          imageURL: rest.image_url,
          category: category,
          restURL: rest.url,
          candidate: 1,
          round: 1
        };
        restaurantsToSave.push(newRestaurant);
      });
      let aRCMD = "INSERT INTO rtRestaurants (restID, gameID, posVotes, negVotes, name, price, rating, address, imageURL, category, restURL, candidate, round ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
      rtDB.serialize(function() {
        rtDB.run("BEGIN TRANSACTION");
        restaurantsToSave.forEach(entry => {
          let irCMD = rtDB.prepare(aRCMD);
          irCMD.run(entry.restID, entry.gameID, entry.posVotes, entry.negVotes, entry.name, entry.price, entry.rating, entry.address, entry.imageURL, entry.category, entry.restURL, entry.candidate, entry.round, function(err) {
            if (err) {
              console.log("[DB]: " + err.message);
              dbErr = true;
            }
          });
          irCMD.finalize();
        });
        rtDB.run("COMMIT");
      });
      if (dbErr == true) {
        console.log("[DB]: Error storing restaurants.");
        socket.emit('servererr', "Error storing restaurants.");
      } else {
        console.log("[GAME " + socket.gameid + "] Stored " + restaurantsToSave.length + " restaurants.");
        emitGameStart(socket.gameid);
      } 
    } else {
      noRestaurantsFound(socket);
    }
  } else {
    socket.emit('servererr', "Couldn't find your Game ID.");
  }
};

// Print error if no restaurants found in Yelp API query
function noRestaurantsFound(socket) {
  socket.emit('servererr', "Sorry, we couldn't find any restaurants matching your search.");
};

// Helper function to store Yelp restaurant data
// Returns address in correct format
function createAddressHelper(location) {
  let address = "";
  location.display_address.forEach( (component, index) => {
    if (index === 0) {
      address += component;
    } else {
      address += ", " + component;
    }
  });
  return address;
};

// Helper function to store Yelp restaurant data
// Returns category in correct format
function categoryHelper(categories) {
  let categoryOne = categories[0];
  if (categoryOne !== undefined || categoryOne !== null) {
    return categoryOne.title;
  }
  return "";
};

/* WEBSOCKETS */
// Create new Websocket server and init methods
// We have creategame, joingame, disconnect, startgame, and playervote
// Each of these call the respective javascript functions down below
const server = http.createServer(app);
const io = require('socket.io')(server);
io.on('connection', (socket) => {
  console.log('[SIO] Player connected.');
  printNumServerClients();
  socket.on('creategame', (msg) => {
    createGame(socket);
  });
  socket.on('joingame', (data) => {
    joinGame(socket, data);
  });
  socket.on('disconnect', (socketClient) => {
    console.log('[SIO] Player disconnected.');
    if (socket.gameid !== undefined) {
      updateNumPlayers(socket.gameid);
    }
    printNumServerClients();
  }); 
  socket.on('startgame', (data) => {
    getRestaurantsForGame(data.keywords, data.location, socket);
  });
  socket.on('playervote', (data) => {
    processVote(data, socket);
  });
});

// Print the number of clients for the Websockets server
// For debugging purposes
function printNumServerClients() {
  io.clients((err, clients) => {
    if (err) console.log(err.message);
    console.log('[SIO] Number of server clients: ' + clients.length);
  });
};

// called on creategame Websocket method
// Creates a new game with a new random game id
function createGame(socket) {
  var gameID = getRandID(4);
  console.log("[SERVER]: Creating new game with ID: " + gameID);
  let cGCMD = "INSERT INTO rtGames ( id, numPlayers, currRound ) VALUES (?,?,?) ";
  rtDB.run(cGCMD, gameID, 0, 1, function(err) {
    if (err) {
      console.log("[DB] Failed to create the game entry.");
      console.log("[DB] Error: " + err.message);
      socket.emit('servernotif', 'Failed to create the game.');
    } else {
      socket.emit('servernotif', 'Game created!');
      socket.emit('gameid', gameID);
      socket.join(gameID, () => {
        socket.gameid = gameID;
        socket.emit('servernotif', `Joined your new game with id ${gameID}.`);
        updateNumPlayers(gameID);
      })
    }
  });
};

// called on joingame Websocket method
// allows user to join game with matching gameid
// If no game with matching id exists, report error
function joinGame(socket, gameid) {
  rtDB.serialize(function() {
    let jgCMD = "SELECT * FROM rtGames WHERE id='" + gameid + "';";
    rtDB.get(jgCMD, [], function(err, row) {
      if (err) {
        socket.emit('servererr', "Sorry, we encountered an error.");
      } else {
        if (row !== undefined) {
          socket.join(gameid, () => {
            socket.gameid = gameid;
            updateNumPlayers(gameid);
            socket.emit('servernotif', "Joined game with id " + gameid);
          });
        } else {
          socket.emit('servererr', "Sorry, we couldn't find a game with that ID.");
        }
      }
    });
  });
};

// helper function to set the numPlayers member of rtGames table to correct value upon player leaving or entering
function updateNumPlayers(gameID) {
  let room = io.sockets.adapter.rooms[gameID];
  if (room !== undefined) {
    let newPlayerNum = room.length;
    console.log("[GAME " + gameID + "] Number of players: " + newPlayerNum);
    let uPCMD = "UPDATE rtGames SET numPlayers = ? WHERE id = ?";
    rtDB.run(uPCMD, newPlayerNum, gameID, function(err) {
      if (err) {
        console.log("[DB] Error: " + err.message);
      } else {
        console.log("[DB] Updated game entry.")
      }
    });
  }
};

// Print that game has started to players
function emitGameStart(gameid) {
  if (gameid !== undefined) {
    io.in(gameid).emit('gamestart');
    gameplay(gameid);
  }
};

/* GAME LOGIC */
// Running game with matching gameid for current user
function gameplay(gameid) {
  sendNewCandidate(gameid);
};

// Send current user to game with matching gameid
function sendNewCandidate(gameid) {
  if (gameid !== undefined) {
    console.log("Searching with gameid " + gameid);
    try {
      rtDB.serialize(function() {
        let crCMD = "SELECT * FROM rtGames WHERE id='" + gameid + "';";
        rtDB.get(crCMD, [], function(err, row) {
          if (err) {
            throw err;
          } else {
            if (row !== undefined) {
              newCandidateLogic(gameid, row.currRound);
            } else {
              let ngErr = {message: "No matching game found."};
              throw ngErr;
            }
          }
        });
      });  
    } catch (err) {
      console.log("[DB]: " + err.message);
      io.in(gameid).emit('servererr', "Error retrieving a new restaurant choice.");
    }
  }
};

// Send new candidate into current round
function newCandidateLogic(gameid, currRound) {
  try {
    /* END GAMEPLAY AFTER THREE ROUNDS */
    console.log("[GAME " + gameid + "]: Current round: " + currRound);
    if (currRound <= 3) {
      let gcCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + gameid + "' AND candidate=1 AND round=" + currRound + ";";
      rtDB.all(gcCMD, [], function(err, rows) {
        if (err) {
          throw err;
        } else {
          if (rows.length === 0) {
            /* NO RESTAURANTS LEFT IN THE CURRENT ROUND */
            updateGameRound(gameid);
          } else {
            /* FOUND A RESTAURANT TO SEND */
            console.log("[GAME " + gameid + ", round " + currRound + "]: Found " + rows.length + " restaurants in DB.");
            var candidateToSend = rows[Math.floor(Math.random() * rows.length)];
            io.in(gameid).emit('newcandidate', candidateToSend);
          }
        }
      });
    } else {
      systemEndGameplay(gameid);
    }
  } catch (err) {
    console.log("[DB]: " + err.message);
    io.in(gameid).emit('servererr', "Error retrieving a new restaurant choice.");
  }
};

// Increment the game round for the matching game in rtGames
function updateGameRound(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let grCMD = "UPDATE rtGames SET currRound = currRound+1 WHERE id='" + gameid + "';";
      rtDB.run(grCMD, [], function(err) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "Error updating your game.");
        } else {
          getCurrentRound(gameid);
        }
      })
    });
  }
};

// Get the current game round and push it to the players
function getCurrentRound(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let crCMD = "SELECT * FROM rtGames WHERE id='" + gameid + "';";
      rtDB.get(crCMD, [], function(err, row) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "Error getting update game info.");
        } else {
          console.log(row);
          if (row.currRound !== undefined) {
            io.in(gameid).emit('roundupdate', row.currRound);
            reduceCandidates(gameid);
          }
        }
      });
    });
  }
};

// Each round, make sure half of candidates are eliminated
// If not half are eliminated, eliminate the restaurants with the least amount of votes until half are eliminated 
// If half or more have already been elimated, do not eliminate more
function reduceCandidates(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let grCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + gameid + "';";
      rtDB.all(grCMD, [], function(err, rows) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "Error retrieving restaurants.");
        } else {
          if (rows.length > 0) {
            disableMultiCandidates(gameid, rows);
          } else {
            console.log("[DB]: No rows found.");
            io.in(gameid).emit('servererr', "Error retrieving restaurants.");
          }
        }
      });
    });
  }
};

// Each round, make sure half of candidates are eliminated
// If not half are eliminated, eliminate the restaurants with the least amount of votes until half are eliminated 
// If half or more have already been elimated, do not eliminate more
function disableMultiCandidates(gameid, rows) {
  if (gameid !== undefined && rows !== undefined) {
    rtDB.serialize(function() {
      let rcCMD = "UPDATE rtRestaurants SET candidate=0 WHERE gameID='" + gameid + "' AND restID=?;";
      rtDB.run("BEGIN TRANSACTION");
      rows.sort((a,b) => (a.negVotes > b.negVotes) ? 1 : -1);
      let lowerHalfLength = Math.floor(rows.length /2 );
      let lowerHalf = rows.splice(0, lowerHalfLength);
      lowerHalf.forEach(entry => {
        let pcCMD = rtDB.prepare(rcCMD);
        pcCMD.run(entry.restID, function(err) {
          if (err) {
            console.log("[DB]: " + err.message);
            io.in(gameid).emit('servererr', "Error retrieving restaurants.");
          }
        });
        pcCMD.finalize();
      });
      rtDB.run("COMMIT");
      resetRoundVotes(gameid);
    });
  }
};

// Get the number of candidate restaurants in game with matching gameid
function getNumCandidates(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let grCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + gameid + "' AND candidate=1;";
      rtDB.run(grCMD, [], function(err, rows) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "Error retrieving restaurants.");
        } else {
          return rows.length;
        }
      });
    });
  }
};

// Reset the votes in the current round
function resetRoundVotes(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let rrCMD = "UPDATE rtRestaurants SET posVotes=0, negVotes = 0 WHERE gameID='" + gameid + "';";
      rtDB.run(rrCMD, [], function(err) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "Error updating restaurant votes.");
        } else {
          sendNewCandidate(gameid);
        }
      });
    });
  }
};

// Chosen restaurant found, emit and destroy game
function sendChosen(gameid, candidate) {
  if (gameid !== undefined && candidate !== undefined) {
    io.in(gameid).emit('restchosen', candidate);
    destroyGame(gameid);
  }
};

// End the game and display the winner
function systemEndGameplay(gameid) {
  if (gameid !== undefined && gameid !== "") {
    /* UNANIMOUS DECISION NEVER MADE, SELECT THE LEAST DISLIKED & BREAK TIES. */
    try {
      rtDB.serialize(function() {
        let ldCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + gameid + "' AND candidate=1;";
        rtDB.all(ldCMD, [], function(err, rows) {
          if (err) {
            throw err;
          } else {
            if (rows.length > 0) {
              rows.sort((a,b) => (a.negVotes > b.negVotes) ? 1 : -1);
              let chosenRest = rows[0];
              if (chosenRest !== undefined) {
                sendChosen(gameid, chosenRest);
              } else {
                let nlErr = {message: "Couldn't find a matching row."};
                throw nlErr;
              }
            } else {
              /* CATCH EDGE CASE: EVERY RESTAURANT COMPLETELY DISLIKED & UNANIMOUS DECISION NEVER MADE */
              console.log("[SERVER]: Edge case encountered.");
              systemEndEdgeCase(gameid);
            }
          }
        });
      });
    } catch (err) {
      console.log("[DB]: " + err.message);
      io.in(gameid).emit('servererr', "Error finding a final restaurant.");
    }
  }
};

// Everyone disliked every restaurant, so we have to end the game with a random restaurant
function systemEndEdgeCase(gameid) {
  if (gameid !== undefined && gameid !== "") {
    try {
      rtDB.serialize(function() {
        let arCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + gameid + "';";
        rtDB.all(arCMD, [], function(err, rows) {
          if (err) {
            throw err;
          } else {
            if (rows.length > 0) {
              var restToSend = rows[Math.floor(Math.random() * rows.length)];
              sendChosen(gameid, restToSend);
            } else {
              let nrErr = {message: "Couldn't find any matching rows."};
              throw nrErr;
            }
          }
        });
      });
    } catch (err) {
      console.log("[DB]: " + err.message);
      io.in(gameid).emit('servererr', "Error finding a final restaurant.");
    }
  }
};

// Process vote from current player
// Send to handlePosVote if positive vote
// Send to handleNegVote if negative vote
function processVote(data, socket) {
  if (data.gameid !== undefined && data.gameid !== "" && data.restID !== undefined && data.restID !== "") {
    socket.emit('votereceived');
    if (data.vote === 1) {
      handlePosVote(data, socket);
    } else if (data.vote === 0) {
      handleNegVote(data, socket);
    }
  }
};

// Handle negative vote from current player
// Update the related restaurant data
// Update the global data
// See if restaurant is chosen as final restaurant
function handlePosVote(data, socket) {
  try {
    let retrievedGame = {};
    rtDB.serialize(function() {
      let ggCMD = "SELECT * FROM rtGames WHERE id='" + data.gameid + "';";
      rtDB.get(ggCMD, [], (err, game) => {
        if (err) {
          throw err;
        } else {
          retrievedGame = game;
          console.log("[DB]: Retrieved game with ID: " + game.id);
        }
      });
      let urCMD = "UPDATE rtRestaurants SET posVotes = posVotes+1 WHERE gameID='" + data.gameid + "' AND restID='" + data.restID + "';";
      rtDB.run(urCMD, [], (err) => {
        if (err) {
          throw err;
        } else {
          console.log("[DB]: Updated restaurant with ID:" + data.restID);
        }
      });
      let nrCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + data.gameid + "' AND restID='" + data.restID + "';";
      rtDB.get(nrCMD, [], (err, row) => {
        if (err) {
          throw err;
        } else {
          if (retrievedGame.numPlayers == row.posVotes) {
            /* IF ALL PLAYERS HAVE AGREED */
            sendChosen(data.gameid, row);
          } else if (retrievedGame.numPlayers == (row.posVotes + row.negVotes)) {
            /* IF ALL PLAYERS HAVE VOTED, NO UNANIMOUS DECISION */
            updateRestaurantRound(data.gameid, data.restID);
          } else {
            /* OTHERWISE, PLAYERS WAIT UNTIL VOTING IS COMPLETED. */
            updateCurrentVotes(data.gameid, retrievedGame.numPlayers, row.posVotes, row.negVotes);
          }
        }
      });
    });
  } catch(err) {
    console.log("[DB]: " + err);
    socket.emit('servererr', "We encountered an error processing your vote.");
  }
};

// Handle negative vote from current player
// Update the related restaurant data
// Update the global data
// See if restaurant needs to be eliminated
function handleNegVote(data, socket) {
  try {
    let retrievedGame = {};
    rtDB.serialize(function() {
      let ggCMD = "SELECT * FROM rtGames WHERE id='" + data.gameid + "';";
      rtDB.get(ggCMD, [], (err, game) => {
        if (err) {
          throw err;
        } else {
          retrievedGame = game;
          console.log("[DB]: Retrieved game with ID: " + game.id);
        }
      });
      let urCMD = "UPDATE rtRestaurants SET negVotes = negVotes+1 WHERE gameID='" + data.gameid + "' AND restID='" + data.restID + "';";
      rtDB.run(urCMD, [], (err) => {
        if (err) {
          throw err;
        } else {
          console.log("[DB]: Updated restaurant with ID:" + data.restID);
        }
      });
      let nrCMD = "SELECT * FROM rtRestaurants WHERE gameID='" + data.gameid + "' AND restID='" + data.restID + "';";
      rtDB.get(nrCMD, [], (err, row) => {
        if (err) {
          throw err;
        } else {
          if (retrievedGame.numPlayers == row.negVotes) {
            /* IF ALL PLAYERS HAVE DISAGREED */
            disableCandidacy(data.gameid, data.restID);
          } else if (retrievedGame.numPlayers == (row.posVotes + row.negVotes)) {
            /* IF ALL PLAYERS HAVE VOTED, NO UNANIMOUS DECISION */
            updateRestaurantRound(data.gameid, data.restID);
          } else {
            /* OTHERWISE, PLAYERS WAIT UNTIL VOTING IS COMPLETED. */
            updateCurrentVotes(data.gameid, retrievedGame.numPlayers, row.posVotes, row.negVotes);
          }
        }
      });
    });
  } catch(err) {
    console.log("[DB]: " + err.message);
    socket.emit('servererr', "We encountered an error processing your vote.");
  }
};

// Update the round member of restaurant with matching restID
function updateRestaurantRound(gameid, restID) {
  if (gameid !== undefined && gameid !== "" && restID !== undefined && restID !== "") {
    rtDB.serialize(function() {
      let rrCMD = "UPDATE rtRestaurants SET round = round+1 WHERE gameID='" + gameid +"' AND restID='" + restID + "';";
      rtDB.run(rrCMD, [], function(err) {
        if (err) {
          console.log("[DB]: " + err.message);
          io.in(gameid).emit('servererr', "We encountered an error processing your restaurants.");
        } else {
          sendNewCandidate(gameid);
        }
      })
    });
  }
};

// Upadate the members of Websocket game given variables
function updateCurrentVotes(gameid, numPlayers, posVotes, negVotes) {
  io.in(gameid).emit('updatecurrentvotes', {
    gameid: gameid,
    numPlayers: numPlayers,
    currVotes: posVotes + negVotes
  });
};

// Disable restaurant with matching restID from being final candidate
function disableCandidacy(gameid, restID) {
  rtDB.serialize(function() {
    let dcCMD = "UPDATE rtRestaurants SET candidate=0 WHERE gameID='" + gameid + "' AND restID='" + restID + "';";
    rtDB.run(dcCMD, [], (err) => {
      if (err) {
        console.log("[DB]: An error occured disabling candidacy: " + err.message);
      } else {
        console.log("[GAME " + gameid + "]: Disabled candidacy for restaurant with ID: " + restID);
        sendNewCandidate(gameid);
      }
    });
  });
};

// Delete all game data from rtRestaurants table
function destroyGame(gameid) {
  if (gameid !== undefined && gameid !== "") {
    console.log("[SERVER]: Destorying finished game with ID: " + gameid + ".");
    rtDB.serialize(function() {
      let drCMD = "DELETE FROM rtRestaurants WHERE gameID='" + gameid + "';";
      rtDB.run(drCMD, [], function(err) {
        if (err) {
          console.log("[DB]: Error deleting restaurant rows: " + err.message);
        } else {
          console.log("[DB]: " + this.changes + " Rows in restaurants table deleted succesfully.");
          deleteGameRecord(gameid);
        }
      });
    });
  }
};

// Delete all game data from rtGames table
function deleteGameRecord(gameid) {
  if (gameid !== undefined && gameid !== "") {
    rtDB.serialize(function() {
      let dgCMD = "DELETE FROM rtGames WHERE id='" + gameid + "';";
      rtDB.run(dgCMD, [], function(err) {
        if (err) {
          console.log("[DB]: Error deleting game row: " + err.message);
        } else {
          console.log("[DB]: " + this.changes + " Game records deleted succesfully.");
        }
      })
    });
  }
};

/* REQUEST LISTENER */
server.listen(process.env.PORT, () => {
  console.log(`Server started on port ${server.address().port}`);
});