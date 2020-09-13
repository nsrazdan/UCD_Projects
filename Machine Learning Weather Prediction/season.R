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