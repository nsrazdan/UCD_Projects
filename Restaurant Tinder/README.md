# ECS162 Final Project - Restaurant Tinder
## Created by Nikhil Razdan, Ethan Turner, and Robert Gutknecht

### Design Choices:
- We opted to round restaurant ratings down to the nearest star as to not have to rely on beta unicode symbols, displaying additional images, or having to import another font face.
- Tinder-style implementation, with each user voting each restaurant either up or down each round
- To prevent issues with socket reconnection, the game host plays on the Host Game page, while others play on a designated gameplay page

### Project Logic:
- Maximum of three rounds will be played
- Restaurants are elimated if they have no votes at the end of a round
- Final choice is restaurant that is unanimously voted for in any round, or restaurant that has the most votes at the end of the 3 rounds
- If multiple restaurants fit the description for being the final choice, one is chosen at random
- If everyone dislikes every single candidate restaurant, a random choice is made from the potential candidates

### Functionality:
- Support for multiple concurrent games in database and in websockets
- Support for location and keyword search for restaurants
- Autocomplete for keywords
- Ability to remove keywords once added
- Error reported if no restaurants matching description found
- Unique game code generated when hosting new game
- Game completely removed from database upon termination
- Image, price, rating, address, Yelp link displayed for each restaurant during game