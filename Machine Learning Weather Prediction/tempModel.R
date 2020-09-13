runLMTemp <- function(trainingdataset) {
  k <- (ncol(trainingdataset) - 1) / 5
  xnam <- paste0("trainingdata[,", 1:(k * 5), "]")
  print(paste0("trainingdata[,", k * 5 + 1,"] ~", paste0(xnam, collapse="+")))
  res <- lm(as.formula(paste0("trainingdata[,", k * 5 + 1,"] ~", paste0(xnam, collapse="+"))))
  return(res)
}

createTrainingDataTemp <- function(k) {
  trainingdata <- matrix(ncol=(k * 5 + 1), nrow=(365 - k))
  
  for (i in (k+1):365) {
    colTracker <- k * 5
    for (j in 1:k) {
      trainingdata[i - k, colTracker - 4] <- day1$temp[i - j]
      trainingdata[i - k, colTracker - 3] <- day1$atemp[i - j]
      trainingdata[i - k, colTracker - 2] <- as.integer(day1$season[i - j] == 1)
      trainingdata[i - k, colTracker - 1] <- as.integer(day1$season[i - j] == 2)
      trainingdata[i - k, colTracker] <- as.integer(day1$season[i - j] == 3)
      colTracker <- colTracker - 5
    }
    trainingdata[i - k, k * 5 + 1] <- day1$temp[i]
  }
  print(trainingdata)
  return(trainingdata)
}

crossValidateTemp <- function(coefficients, k) {
  print(length(coefficients))
  values <- rep(0, 731 - 365)
  print(length(values))
  for (i in 1:(731 - 365)) {
    values[i] <- predictTemp(i + 365, coefficients, k)
    print(values[i])
  }
  return(values)
}

predictTemp <- function(day, coefficients, k) {
  winter <- as.integer(day1$season == 1)
  spring <- as.integer(day1$season == 2)
  summer <- as.integer(day1$season == 3)
  curr <- coefficients[1]
  i <- day
  daytracker <- 0
  for (j in seq(2, length(coefficients), 5)) {
    # cat(paste0("Printing day ", i - k + daytracker, "\nCoefficient: ",  coefficients[j], " ", coefficients[j + 1],
    #              # " ", coefficients[j + 2], " ", coefficients[j + 3], " ", coefficients[j + 4],
                 # "\nTEMP: ", day1$temp[i - k + daytracker], " ATEMP: ", day1$atemp[i - k + daytracker], " Season: ", day1$season[i - k + daytracker], "\n"))
    diff <- coefficients[j] * day1$temp[i - k + daytracker] + coefficients[j+1] * day1$atemp[i - k + daytracker] + coefficients[j+2] * 
      winter[i - k + daytracker] + coefficients[j+3] * spring[i - k + daytracker] + coefficients[j+4] * summer[i - k + daytracker]
    curr <- curr + diff
    # cat(paste0("Addition: ", diff, " New Temp Value: ", curr, "\n\n"))
    daytracker <- daytracker + 1
  }
  print(paste0("Final Prediction: ", curr, " Actual Temp: ", day1$temp[i]))
  return(curr)
}
