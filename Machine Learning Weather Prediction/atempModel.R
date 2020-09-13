runLMATemp <- function(trainingdataset, k) { # load trainingdata into trainingdata var
  xnam <- paste0("trainingdata[,", 1:(k * 7), "]")
  res <- lm(as.formula(paste0("trainingdata[,", k * 7 + 1,"] ~", paste0(xnam, collapse="+"))))
  return(res)
}

createTrainingDataATemp <- function(k) {
  trainingdata <- matrix(ncol=(k * 7 + 1), nrow=(365 - k))
  print(dim(trainingdata))
  for (i in (k+1):365) {
    colTracker <- k * 7
    for (j in 1:k) {
      trainingdata[i - k, colTracker - 6] <- day1$temp[i - j]
      trainingdata[i - k, colTracker - 5] <- day1$atemp[i - j]
      trainingdata[i - k, colTracker - 4] <- as.integer(day1$season[i - j] == 1)
      trainingdata[i - k, colTracker - 3] <- as.integer(day1$season[i - j] == 2)
      trainingdata[i - k, colTracker - 2] <- as.integer(day1$season[i - j] == 3)
      trainingdata[i - k, colTracker - 1] <- day1$hum[i - j]
      trainingdata[i - k, colTracker] <- day1$windspeed[i - j]
      colTracker <- colTracker - 7
    }
    trainingdata[i - k, k * 7 + 1] <- day1$atemp[i]
  }
  return(trainingdata)
}

runModifiedLMATemp <- function(trainingdataset, k) { # load trainingdata into trainingdata var first
  xnam <- paste0("trainingdata[,", 1:(k * 9), "]")
  res <- lm(as.formula(paste0("trainingdata[,", k * 9 + 1,"] ~", paste0(xnam, collapse="+"))))
  return(res)
}

modifiedCreateTrainingDataATemp <- function(k) {
  trainingdata <- matrix(ncol=(k * 9 + 1), nrow=(365 - k))
  print(dim(trainingdata))
  for (i in (k+1):365) {
    colTracker <- k * 9
    for (j in 1:k) {
      trainingdata[i - k, colTracker - 8] <- day1$temp[i - j]
      trainingdata[i - k, colTracker - 7] <- day1$atemp[i - j]
      trainingdata[i - k, colTracker - 6] <- as.integer(day1$season[i - j] == 1)
      trainingdata[i - k, colTracker - 5] <- as.integer(day1$season[i - j] == 2)
      trainingdata[i - k, colTracker - 4] <- as.integer(day1$season[i - j] == 3)
      trainingdata[i - k, colTracker - 3] <- day1$hum[i - j]
      trainingdata[i - k, colTracker - 2] <- day1$windspeed[i - j]
      trainingdata[i - k, colTracker - 1] <- as.integer(day1$weathersit[i - j] == 1)
      trainingdata[i - k, colTracker] <- as.integer(day1$weathersit[i - j] == 2)
      colTracker <- colTracker - 9
    }
    trainingdata[i - k, k * 9 + 1] <- day1$atemp[i]
  }
  return(trainingdata)
}

crossValidateModifiedATemp <- function(coefficients, k) {
  print(length(coefficients))
  values <- rep(0, 731 - 365)
  print(length(values))
  for (i in 1:(731 - 365)) {
    values[i] <- predictModifiedATemp(i + 365, coefficients, k)
    print(values[i])
  }
  return(values)
}


predictModifiedATemp <- function(day, coefficients, k) {
  winter <- as.integer(day1$season == 1)
  spring <- as.integer(day1$season == 2)
  summer <- as.integer(day1$season == 3)
  clear <- as.integer(day1$weathersit == 1)
  cloudy <- as.integer(day1$weathersit == 2)
  curr <- coefficients[1]
  i <- day
  daytracker <- 0
  for (j in seq(2, length(coefficients), 9)) {
    diff <- coefficients[j] * day1$temp[i - k + daytracker] + coefficients[j+1] * day1$atemp[i - k + daytracker] + coefficients[j+2] *
      winter[i - k + daytracker] + coefficients[j+3] * spring[i - k + daytracker] + coefficients[j + 4] * summer[i - k + daytracker] +
      coefficients[j + 5] * day1$hum[i - k + daytracker] + coefficients[j + 6] * day1$windspeed[i - k + daytracker] + coefficients[j + 7] *
      clear[i - k + daytracker] + coefficients[j + 8] * cloudy[i - k + daytracker]
    curr <- curr + diff
    daytracker <- daytracker + 1
    
  }
  print(paste0("Final Prediction: ", curr, " Actual Temp: ", day1$atemp[i]))
  return(curr)
}


crossValidateATemp <- function(coefficients, k) {
  print(length(coefficients))
  values <- rep(0, 731 - 365)
  print(length(values))
  for (i in 1:(731 - 365)) {
    values[i] <- predictATemp(i + 365, coefficients, k)
    print(values[i])
  }
  return(values)
}

predictATemp <- function(day, coefficients, k) {
  winter <- as.integer(day1$season == 1)
  spring <- as.integer(day1$season == 2)
  summer <- as.integer(day1$season == 3)
  curr <- coefficients[1]
  i <- day
  daytracker <- 0
  for (j in seq(2, length(coefficients), 7)) {
    diff <- coefficients[j] * day1$temp[i - k + daytracker] + coefficients[j+1] * day1$atemp[i - k + daytracker] + coefficients[j+2] *
      winter[i - k + daytracker] + coefficients[j+3] * spring[i - k + daytracker] + coefficients[j + 4] * summer[i - k + daytracker] +
      coefficients[j + 5] * day1$hum[i - k + daytracker] + coefficients[j + 6] * day1$windspeed[i - k + daytracker]
    curr <- curr + diff
    daytracker <- daytracker + 1
  }
  print(paste0("Final Prediction: ", curr, " Actual Temp: ", day1$atemp[i]))
  return(curr)
}

runBadLMATemp <- function(trainingdata, k) {
  xnam <- paste0("trainingdata[,", 1:(k * 5), "]")
  res <- lm(as.formula(paste0("trainingdata[,", k * 5 + 1,"] ~", paste0(xnam, collapse="+"))))
  return(res)
}

badCreateTrainingDataATemp <- function(k) {
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
    trainingdata[i - k, k * 5 + 1] <- day1$atemp[i]
  }
  return(trainingdata)
} 


badCrossValidateTemp <- function(coefficients, k) {
  print(length(coefficients))
  values <- rep(0, 731 - 365)
  print(length(values))
  for (i in 1:(731 - 365)) {
    values[i] <- badPredictTemp(i + 365, coefficients, k)
    print(values[i])
  }
  return(values)
}

badPredictTemp <- function(day, coefficients, k) {
  winter <- as.integer(day1$season == 1)
  spring <- as.integer(day1$season == 2)
  summer <- as.integer(day1$season == 3)
  curr <- coefficients[1]
  i <- day
  daytracker <- 0
  for (j in seq(2, length(coefficients), 5)) {
    diff <- coefficients[j] * day1$temp[i - k + daytracker] + coefficients[j+1] * day1$atemp[i - k + daytracker] + coefficients[j+2] *
      winter[i - k + daytracker] + coefficients[j+3] * spring[i - k + daytracker] + coefficients[j + 4] * summer[i - k + daytracker]
    curr <- curr + diff
    daytracker <- daytracker + 1
  }
  print(paste0("Final Prediction: ", curr, " Actual Temp: ", day1$atemp[i]))
  return(curr)
}
