library(lubridate)

# Grid load and weather data
load_data = read.csv("../data/ercot/load_data.csv")
temperature_impute = read.csv("../data/ercot/weather_processed/temperature_impute.csv", row.names=1)
dewpoint_impute = read.csv("../data/ercot/weather_processed/dewpoint_impute.csv", row.names=1)

# some dates have missing weather data
# Keep the load data for dates when we have weather data
mysub = which(ymd_hms(load_data$Time) %in% ymd_hms(rownames(temperature_impute)))
load_data = load_data[mysub,]

# De-duplicate the weather data by merging on first match of date
temp_ind = match(ymd_hms(load_data$Time), ymd_hms(rownames(temperature_impute)))
temperature_impute = temperature_impute[temp_ind,]
dewpoint_impute = dewpoint_impute[temp_ind,]

# Take the time stamps from the load data
time_stamp = ymd_hms(load_data$Time)

# Verify that the time stamps match row by row across all data frames
all(time_stamp ==  ymd_hms(rownames(temperature_impute)))
all(time_stamp ==  ymd_hms(rownames(dewpoint_impute)))

# start a new data frame
# hour of day, day of week, month as predictors
load_coast = data.frame(hour = hour(time_stamp), day = wday(time_stamp), month = month(time_stamp))

# let's take weather data at KHOU (Hobby airport)
load_coast$KHOU_temp = temperature_impute$KHOU
load_coast$KHOU_dewpoint = dewpoint_impute$KHOU

# Now run PCA on the other weather stations
KHOU_colind = which(colnames(temperature_impute) == 'KHOU')
weather_all = as.matrix(cbind(temperature_impute[,-KHOU_colind], dewpoint_impute[,-KHOU_colind]))
pc_weather = prcomp(weather_all, rank=10, scale=TRUE)

# notice 10 summary features gets me 95% of the overall variation in 510 original features
# pretty nice compression ratio!
summary(pc_weather)

# extract the scores to use as summary features
weather_scores = pc_weather$x

# What do they look like?

# to me this looks something like an overall summer/winter index
plot(time_stamp, weather_scores[,1], type='l')

# Not 100% sure what these lower-order PCs are
# they might show geographic contrasts
# might need to plot the loadings station by station on a map!
# the lat/lon coordinates of all stations are on the website
# see data/ercot/station_data.csv
plot(time_stamp, weather_scores[,2], type='l')
plot(time_stamp, weather_scores[,3], type='l')
plot(time_stamp, weather_scores[,4], type='l')

# let's add the PC scores and the target (COAST) variable
# to the data frame we're building 
load_coast = cbind(load_coast, weather_scores)
load_coast$COAST = load_data$COAST

# check it looks right
head(load_coast)

# write the file out to the hard drive
write.csv(load_coast, '../data/load_coast.csv', quote=FALSE)
