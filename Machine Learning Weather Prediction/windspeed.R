runWindSpeed <- function(){
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