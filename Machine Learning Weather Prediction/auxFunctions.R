removeNA <- function(x) { # Remove the NA for season analysis
  res <- c(0)
  for (i in 1:length(x)) {
    if (!is.na(x[i])) {
      res <- append(res, x[i])
    }
  }
  return(res)
}

analysis <- function(chosenSeason) { # Analyze mean and median of seasons
  temp <- c(0)
  for (i in 1:731) {
    if (day1$season[i] == chosenSeason) {
      temp <- append(temp, day1$temp[i])
    }
  }
  temp <- removeNA(temp)
  print(median(temp))
  print(mean(temp))
}
