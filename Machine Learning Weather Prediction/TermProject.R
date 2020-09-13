# tempModel.R
runLMTemp <- function(trainingdataset) {
  k <- (ncol(trainingdataset) - 1) / 5
  xnam <- paste0("trainingdata[,", 1:(k * 5), "]")
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
    diff <- coefficients[j] * day1$temp[i - k + daytracker] + coefficients[j+1] * day1$atemp[i - k + daytracker] + coefficients[j+2] * 
      winter[i - k + daytracker] + coefficients[j+3] * spring[i - k + daytracker] + coefficients[j+4] * summer[i - k + daytracker]
    curr <- curr + diff
    daytracker <- daytracker + 1
  }
  print(paste0("Final Prediction: ", curr, " Actual Temp: ", day1$temp[i]))
  return(curr)
}

# atempModel.R
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

# season.R
seasonanalysis <- function() {
  res <- rep(0, 8)
  names(res) <- c("Winter Mean", "Winter Median",
                  "Spring Mean", "Spring Median",
                  "Summer Mean", "Summer Median",
                  "Fall Mean", "Fall Median")
  res[1] <- mean(day1$temp[which(day1$season == 1)])
  res[2] <- median(day1$temp[which(day1$season == 1)])
  
  res[3] <- mean(day1$temp[which(day1$season == 2)])
  res[4] <- median(day1$temp[which(day1$season == 2)])
  
  res[5] <- mean(day1$temp[which(day1$season == 3)])
  res[6] <- median(day1$temp[which(day1$season == 3)])
  
  res[7] <- mean(day1$temp[which(day1$season == 4)])
  res[8] <- median(day1$temp[which(day1$season == 4)])
  return(res)
}

# humidity.R
runHumidity <- function() {
  library(regtools)
  data(day1)
  day1 <- day1[,c(3,9,10,11,12,13)]
  head(day1)
  
  temp3ago <- abs(day1$temp[1:362]-day1$atemp[1:362])
  temp2ago <- abs(day1$temp[2:363]-day1$atemp[2:363])
  temp1ago <- abs(day1$temp[3:364]-day1$atemp[3:364])
  hum3ago <- day1$hum[1:362]
  hum2ago <- day1$hum[2:363]
  hum1ago <- day1$hum[3:364]
  currhum <- day1$hum[4:365]
  winter <- as.integer(day1$season[4:365] == 1)
  spring <- as.integer(day1$season[4:365] == 2)
  summer <- as.integer(day1$season[4:365] == 3)
  seasons <- cbind(winter, spring, summer)
  inside3x <- cbind(temp3ago, temp2ago, temp1ago, 
                    hum3ago, hum2ago, hum1ago,
                    seasons)
  lmout <- lm(currhum ~ temp3ago+temp2ago+temp1ago+
                hum3ago+hum2ago+(hum1ago)
              +winter+spring+summer)
  
  otemp3ago <- abs(day1$temp[366:728]-day1$atemp[366:728])
  otemp2ago <- abs(day1$temp[367:729]-day1$atemp[367:729])
  otemp1ago <- abs(day1$temp[368:730]-day1$atemp[368:730])
  ohum3ago <- day1$hum[366:728]
  ohum2ago <- day1$hum[367:729]
  ohum1ago <- day1$hum[368:730]
  ocurrhum <- day1$hum[369:731]
  owinter <- as.integer(day1$season[369:731] == 1)
  ospring <- as.integer(day1$season[369:731] == 2)
  osummer <- as.integer(day1$season[369:731] == 3)
  oseasons <- cbind(owinter, ospring, osummer)
  outside2x <- cbind(otemp3ago,otemp2ago,otemp1ago, 
                     ohum3ago,ohum2ago, ohum1ago, oseasons)
  
  predictxx <- rep(0,363)
  startday <- 1
  for (rep in 1:363) {
    predictxx[rep] <- predictxx[rep] + lmout$coefficients[1]
    for (co in 2:9) {
      predictxx[rep] <- predictxx[rep] + lmout$coefficients[co] * outside2x[startday,co-1]
    }
    startday <- startday + 1
  }
  
  plot(predictxx, day1$hum[369:731], xlab = "Predicted Humidity", ylab = "Actual Humidity", main = bquote(atop("Predicted vs Actual Humidity w/ k = 3", "Factors: Abs(Temp-Atemp), Season, Humidity")))
  abline(0,1)
}

# windspeed.R
runWindSpeed <- function() {
  library(regtools) 
  data(day1)
  
  day1 <- day1[,c(1,2,3,9,10,11,12,13)]
  head(day1)
  
  temp2ago <- abs(day1$temp[1:363] - day1$atemp[1:363])
  temp1ago <- abs(day1$temp[2:364] - day1$atemp[2:364])
  ws2ago <- day1$windspeed[1:363]
  ws1ago <- day1$windspeed[2:364]
  currws <- day1$windspeed[3:365]
  winter <- as.integer(day1$season[3:365] == 1)
  spring <- as.integer(day1$season[3:365] == 2)
  summer <- as.integer(day1$season[3:365] == 3)
  inside <- cbind(temp2ago, temp1ago, atemp2ago, atemp1ago, ws2ago, ws1ago)
  lmout <- lm(currws ~ atemp2ago+atemp1ago+
                +ws2ago+(ws1ago)+
                winter+spring+summer)
  
  oatemp2ago <- abs(day1$atemp[367:729])
  oatemp1ago <- abs(day1$atemp[368:730])
  ows2ago <- day1$windspeed[367:729]
  ows1ago <- day1$windspeed[368:730]
  ocurrws <- day1$windspeed[369:731]
  winter <- as.integer(day1$season[369:731] == 1)
  spring <- as.integer(day1$season[369:731] == 2)
  summer <- as.integer(day1$season[369:731] == 3)
  o2x <- cbind(oatemp2ago, oatemp1ago, 
               ows2ago, ows1ago,
               winter,spring,summer)
  
  predictxx <- rep(0,363)
  startday <- 1
  for (rep in 1:363) {
    predictxx[rep] <- predictxx[rep] + lmout$coefficients[1]
    for (co in 2:7) {
      predictxx[rep] <- predictxx[rep] + lmout$coefficients[co] * o2x[startday,co-1]
    }
    startday <- startday + 1
  }
  
  plot(predictxx, day1$windspeed[369:731], xlab = "Predicted Windspeed", ylab = "Actual Windspeed", 
       main = bquote(atop("Predicted vs Actual Windspeed w/ k = 2", "Factors: Abs(Temp-ATemp), Windspeed, Season")))
  abline(0,1)
}

# weathersit.R
# Plotting simple linear relationships
plot_linear_relationships <- function() {
  plot(day1$weathersit, day1$hum, col = "blue", main = "Weathersit Predicted by Humidity",
       xlab = "Weathersit", ylab = "Humidity")
  abline(lm(day1$hum ~ day1$weathersit), col = "red")
  
  plot(day1$weathersit, day1$windspeed, col = "blue", main = "Weathersit Predicted by Windspeed",
       xlab = "Weathersit", ylab = "Windspeed")
  abline(lm(day1$windspeed ~ day1$weathersit), col = "red")
  
  plot(day1$weathersit, day1$tot, col = "blue", main = "Weathersit Predicted by Total Bikes Registered",
       xlab = "Weathersit", ylab = "Total Bikes Registered")
  abline(lm(day1$tot ~ day1$weathersit), col = "red")
}

### SEQUENTIAL
sim_sequential <- function(num_training, predictors, k, days_ago, plot = NULL) {
  
  # getting test and train x
  trainx <- day1[1:num_training,predictors]
  testx <- day1[(num_training + 1):nrow(day1),predictors]
  
  # adding days_ago data
  for(i in 1:days_ago) {
    data <- day1[1:nrow(day1),predictors]
    for(j in 1:i) {
      data <- rbind(rep(NA, length(predictors)), data)
    }
    trainx <- cbind(trainx, data[1:num_training, ])
    testx <- cbind(testx, data[num_training:(nrow(data) - (i + 1)), ])
  }
  
  # creating test and train y data
  trainy <- day1$weathersit[1:num_training]
  testy <- day1$weathersit[(num_training + 1):nrow(day1)]
  
  # training and evaluating models
  knn_1 <- basicKNN(trainx,as.integer(trainy == 1),testx,k)
  knn_2 <- basicKNN(trainx,as.integer(trainy == 2),testx,k)
  knn_3 <- basicKNN(trainx,as.integer(trainy == 3),testx,k)
  knn_4 <- basicKNN(trainx,as.integer(trainy == 4),testx,k)
  knn_all <- data.frame(knn_1$regests, knn_2$regests, knn_3$regests, 
                        knn_4$regests)
  colnames(knn_all) <- c(1, 2, 3, 4)
  
  # getting model predictions
  predictions <- colnames(knn_all)[max.col(knn_all,ties.method="first")]
  predictions <- strtoi(predictions)
  
  # Plot accuracy for all predictions
  if(!is.null(plot)) {
    plot(testy, predictions, 
         main = "Prediction vs Actual - Sequentially Chosen Data", 
         xlab = "Actual Weathersit", ylab = "Predicted Weathersit",
         xlim = c(1, 3), ylim = c(1,3), 
         col = ifelse(testy == predictions, "green", "red"))
    
    abline(lm(testy ~ predictions), col = "blue")
    lines(c(1, 2, 3), c(1, 2, 3), col = "orange")
  }
  
  # calculate and return accuracy
  accuracy <- sum(testy == predictions) / length(testy)
  return(accuracy)
}

### RANDOM
sim_random <- function(num_training, predictors, k, plot = NULL) {
  
  # getting random values
  rand <- sample(nrow(day1), nrow(day1), replace = FALSE)
  
  # getting test and train x data
  trainx <- day1[rand[1:num_training],predictors]
  testx <- day1[rand[(num_training + 1):nrow(day1)],predictors]
  
  # creating test and train y data
  trainy <- day1$weathersit[rand[1:num_training]]
  testy <- day1$weathersit[rand[(num_training + 1):nrow(day1)]]
  
  # training and evaluating models
  knn_1 <- basicKNN(trainx,as.integer(trainy == 1),testx,k)
  knn_2 <- basicKNN(trainx,as.integer(trainy == 2),testx,k)
  knn_3 <- basicKNN(trainx,as.integer(trainy == 3),testx,k)
  knn_4 <- basicKNN(trainx,as.integer(trainy == 4),testx,k)
  knn_all <- data.frame(knn_1$regests, knn_2$regests, knn_3$regests, 
                        knn_4$regests)
  colnames(knn_all) <- c(1, 2, 3, 4)
  
  # getting model predictions
  predictions <- colnames(knn_all)[max.col(knn_all,ties.method="first")]
  predictions <- strtoi(predictions)
  
  # Plot accuracy for all predictions
  if(!is.null(plot)) {
    plot(testy, predictions, main = "Prediction vs Actual - Randomly Chosen Data", 
         xlab = "Actual Weathersit", ylab = "Predicted Weathersit",
         xlim = c(1, 3), ylim = c(1,3), 
         col = ifelse(testy == predictions, "green", "red"))
    
    abline(lm(testy ~ predictions), col = "blue")
    lines(c(1, 2, 3), c(1, 2, 3), col = "orange")
  }
  
  # calculate and return accuracy
  accuracy <- sum(testy == predictions) / length(testy)
  return(accuracy)
}

seq_model_comparison <- function(num_training, nreps, k, days_ago) {
  linear_data <- rep(0.00, nreps)
  bike_data <- rep(0.00, nreps)
  weather_data <- rep(0.00, nreps)
  time_data <- rep(0.00, nreps)
  
  linear_predictors <- c(10, 11, 12, 16)
  bike_predictors <-  c(10, 11, 14, 15, 16)
  weather_predictors <- c(10, 11, 12, 13)
  time_predictors <- c(10, 11, 3, 4, 5)
  
  for(i in 1:nreps) {
    linear_data[i] <- sim_sequential(num_training, linear_predictors, k, days_ago)
    bike_data[i] <- sim_sequential(num_training, bike_predictors, k, days_ago)
    weather_data[i] <- sim_sequential(num_training, weather_predictors, k, days_ago)
    time_data[i] <- sim_sequential(num_training, time_predictors, k, days_ago)
  }
  
  boxplot(linear_data, bike_data, weather_data, time_data, 
          col = c("blue", "red", "green", "orange"), 
          main = "Prediction Accuracy Distribution", 
          names = c("Linear Data", "Bike Data", "Weather Data", "Time Data"), 
          xlab = "Data Type", 
          ylab = "Prediction Accuracy")
}

rand_model_comparison <- function(num_training, nreps, k, days_ago) {
  linear_data <- rep(0.00, nreps)
  bike_data <- rep(0.00, nreps)
  weather_data <- rep(0.00, nreps)
  time_data <- rep(0.00, nreps)
  
  linear_predictors <- c(10, 11, 12, 16)
  bike_predictors <-  c(10, 11, 14, 15, 16)
  weather_predictors <- c(10, 11, 12, 13)
  time_predictors <- c(10, 11, 3, 4, 5)
  
  for(i in 1:nreps) {
    linear_data[i] <- sim_random(num_training, linear_predictors, k)
    bike_data[i] <- sim_random(num_training, bike_predictors, k)
    weather_data[i] <- sim_random(num_training, weather_predictors, k)
    time_data[i] <- sim_random(num_training, time_predictors, k)
  }
  
  boxplot(linear_data, bike_data, weather_data, time_data, 
          col = c("blue", "red", "green", "orange"), 
          main = "Prediction Accuracy Distribution", 
          names = c("Linear Data", "Bike Data", "Weather Data", "Time Data"), 
          xlab = "Data Type", 
          ylab = "Prediction Accuracy")
}

main <- function() {
  print(sim_sequential(num_training, predictors, k, days_ago))
  print(sim_random(num_training, predictors, k))
  
  seq_data <- rep(0.00, nreps)
  rand_data <- rep(0.00, nreps)
  
  # Run nreps models and find average for sequential and random models
  for(i in 1:nreps) {
    seq_data[i] <- sim_sequential(num_training, predictors, k, days_ago)
    rand_data[i] <- sim_random(num_training, predictors, k)
    cat("Completed model", i, "\n")
  }
  
  plot(1:nreps, seq_data, col = "red", main = "Prediction Accuracy Over 100 Trials", 
       xlab = "Trial Number", ylab = "Prediction Accuracy",
       xlim = c(1, nreps), ylim = c(min(min(seq_data), min(rand_data)) - 0.025, 
                                    max(max(seq_data), max(rand_data)) + 0.025))
  points(1:nreps, rand_data, col = "blue")
  boxplot(rand_data, seq_data, col = c("blue", "red"), 
          main = "Prediction Accuracy Distribution", 
          names = c("Random", "Sequential"), xlab = "Data Type", 
          ylab = "Prediction Accuracy")
}

setup <- function() {
  # Hyper-parameters
  num_training <- 500
  k <- 3
  predictors <- c(10, 11, 12, 13)
  days_ago <- 1
  nreps <- 100
}
