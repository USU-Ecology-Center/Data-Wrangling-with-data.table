###
#
# data.table Workshop
# USU Ecology Center student workshop series
# Michael Stemkovski
#
# - why use data.table
# - reading in data
# - basic syntax
# - sub-setting
# - operations on columns
# - aggregations by groups
# - a few handy extras
#
# You can find this code and other demos here: https://gist.github.com/stemkov
#
###

library(data.table)

### Why use data.table?

# Fast, simplified data reading

# Efficient memory allocation, allowing for:
# - fast operations
# - very large objects

# Simple syntax, enhancing base data.frames
# - concise, readable code
# - don't have to relearn everything, as in tidyverse


### Reading in data

# Lets track how long fread and read.csv each take to read in some data
data_table_time <-system.time(fread("https://raw.githubusercontent.com/stemkov/pheno_variance/main/clean_data/all_data_standardized.csv"))
read_csv_time <- system.time(read.csv("https://raw.githubusercontent.com/stemkov/pheno_variance/main/clean_data/all_data_standardized.csv"))

# data_table_time <- system.time(fread("/home/michael/Documents/Grad School/Research Projects/pheno_variance/clean_data/all_data_standardized.csv"))
# read_csv_time <- system.time(read.csv("/home/michael/Documents/Grad School/Research Projects/pheno_variance/clean_data/all_data_standardized.csv"))

# How much better did fread do?
paste("fread was", round(read_csv_time[3]/data_table_time[3],1), "times faster than read.csv")
paste("if this file had 100 million rows, read.csv would at least", round(read_csv_time[3]*20/60,1), "minutes and likely crash your R session")
paste("if this file had 100 million rows, fread would take about", round(data_table_time[3]*20/60,1), "minutes and run smoothly")

# So, there's no reason to use read.csv ever again ;)
data <- fread("https://raw.githubusercontent.com/stemkov/pheno_variance/main/clean_data/all_data_standardized.csv")

# Side note: This is data from a manuscript that is in review
# You can find a preprint here: https://doi.org/10.1101/2021.10.08.463688


### Basic syntax

# view the data
data

# Similar to data.frames, use [] brackets to look at [rows,] and [,columns]:

# view a column
data[, "species"]
data[, species] # or this
data$species # or this

# view some rows
data[1000:1010,]

# But data.tables enhance data.frames by adding a "by" argument
# Using the form data[rows, columns, by]
# This is written in short-hand with data[i,j,by]
# You can read this as "Take data, subset rows using i, then calculate j grouped by by"


### sub-setting

# You can pull out subsets more neatly:
data[species == "Prunus mume",] # one species
data[is.na(species),] # NAs in species
data[species %in% c("Prunus mume", "Prunus serrulata"),] # two species

# Say we wanted to get observations of 
# just first flowering
# for a plumb species 
# in the year to 2000
# at all sites
data[species == "Prunus mume" & year == 2000 & phenophase == "first_flower",]

### operations on columns

# Say we're interested in comparisons between genera
# We can easily add a new column using the := syntax:
data[, genus := gsub(" .*", "", species)] # this used Regular Expressions (regex)

# You can also use a tidyverse function like word(), though this takes much longer
library(stringr)
data[, genus := word(species, 1)]
# make sure to use the := syntax when adding columns

# You can pass multiple columns to a function in j
# Say we wanted to combine latitude and longitude into a coordinate:
data[, coord := paste(lat, lon, sep=", ")]


# Now, say we wanted to calculate 
# the mean day-of-year
# of first flowering
# for all species of plumbs
# in the year 2000
# at all sites
data[genus == "Prunus" & year == 2000 & phenophase == "first_flower",
     mean(doy)]

mean(data[genus == "Prunus" & year == 2000 & phenophase == "first_flower",
     doy])

### aggregations by groups

# But why is it useful to put the operation inside the [] brackets?
# Because you can use the by argument to perform this operation on multiple groups!
data[, mean(doy), by=.(genus, year, phenophase)]

# We can go ahead and save this summary data.table
# And name the new column
summary_data <- data[, .(mean_doy = mean(doy)), by=.(genus, year, phenophase)] 
# make sure to use the .() notation
summary_data

# We can perform multiple operations by groups at once:
summary_data <- data[, .(mean_doy = mean(doy),
                         mean_temp = mean(tmax),
                         n_sites = .N),
                     by=.(genus, year, phenophase)] 
summary_data

# Lets take a look at our summarized data
plot(mean_doy ~ mean_temp, data=summary_data, pch=20, cex=0.2, ylim=c(0,365), col=as.factor(genus))
plot(n_sites ~ mean_temp, data=summary_data, pch=20, cex=0.2, col=as.factor(genus))

# Using the by= argument also lets you perform operations much more quickly/efficiently
data[, genus := gsub(" .*", "", species)]
data[, genus := gsub(" .*", "", species), by=.(species)]
# repeats operation 460,000 times
ungrouped_time <- system.time(data[, genus := gsub(" .*", "", species)]) 
# repeats operation 2,100 times
grouped_time <- system.time(data[, genus := gsub(" .*", "", species), by=.(species)]) 

paste("this ran", round(ungrouped_time[3]/grouped_time[3],1), "times faster with grouping")


### a few handy extras

# We can combine multiple datasets by key values
# Here are some trait data that we want to merge in with the phenology data
traits <- fread("https://raw.githubusercontent.com/stemkov/pheno_variance/main/clean_data/plant_traits.csv", header=T)

# We can set a key in each of these data.tables which makes subsequent operations easy
setkey(data, species)
setkey(traits, species)
data <- data[traits]
# you can also just use the merge() function: merge(data, traits)

# You can perform multiple operations in a row without making separate objects by chaining:
data[growth_form == "tree",
     .(n_obs = .N),
     by=.(species)] [n_obs > 100] [order(n_obs)]

# Say you wanted to perform the same operation on multiple columns
# You don't have to write them all out if you use the .SDcols special operator:
data[, .SD[c(1,.N)], by=.(genus, phenophase)]
# This gives me the first and last observation for each genus/phenophase group


### Any question/requests?


