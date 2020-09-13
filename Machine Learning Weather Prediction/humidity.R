runHumidity <- function(){
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
