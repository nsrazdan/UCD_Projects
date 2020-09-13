library(regtools)

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
