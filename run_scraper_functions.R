#This file is the master file that will source separate files for all of Crimson scrapping automation
#Any updates to the formulae for these file should be documented here.

# Anyone running this will need a few packages including RSelenium, RMySQL, DBI (possibly others). 
# To install new packages run devtools::install_github("ropensci/RSelenium") and install.packages('RSelenium') in the console. 
# **I highly recommend running R code using the RStudio environment



#Load libraries and source automation helper functions
source('selenium.R')
source('sentiment_data_scrape.R')
#source('emotion_data_scrape.R')
#source('geographic_data_scrape.R')
#source('demographic_data_scrape.R')
library(RSelenium)
library(RMySQL)
library(DBI)

#Use these to turn collection on and off for each data source. T is on, F is off.
sentiment_data_scrape <- T
emotion_data_scrape <- F
demographic_data_scrape <- F
geography_data_scrape <- F

#RSelenium has a main reference class named remoteDriver. 
#To connect to a server you need to instantiate a new remoteDriver with appropriate options.
remDr <- remoteDriver(remoteServerAddr = "192.168.99.100"
                      ,
                      port = 4445
                      ,
                      browserName = "chrome")

#initialize chrome browser
remDr$open()
#login to Chrimson Hexagon
login("https://forsight.crimsonhexagon.com/ch/login", 'steve@spotted.us', 'spotted123')

#check if successfully logged in
if(remDr$getCurrentUrl() == 'https://forsight.crimsonhexagon.com/ch/home') {
  cat('You have sucessfully logged in!')
} else{
  remDr$close()
  cat('There was an error in your login credentials. Please close the ensure you have entered the correct credentials before rerunning!')
  break
}

#Must make sure that you are using the correct monitor name. Please copy and paste your monitor name
monitor_name <-'Monitor'

#get main monitor url
monitor_url <- get_monitor_url(monitor_name)
remDr$navigate(monitor_url)
#get monitor reset url
update_url <-  unlist(get_update_url())
remDr$navigate(monitor_url)
#get sentiment url with daily granularity and "-(RT)" filter applied
sentiment_url <- unlist(get_sentiment_url_filtered())
get_sentiment_ids()

#read in list of celebrity names from preset csv file
celeb_list <- read.csv('C:/Users/pete/OneDrive/Desktop/crimson_selenium/celeb_list.csv')

#set a list of unique celebrity names from your csv containing 
#celebrity names of celebrities you'd like to scrape sentiment data for
namelist <- unique(celeb_list$fullname)

con <- dbConnect(MySQL(),
                 user="analyticDbAdmin", password="R#E30Dh#ZnWL",
                 dbname="spotteddataanalytics", host="analyticproddb1.cjpwtuibxstb.us-west-2.rds.amazonaws.com")

#Pull celebrity twitter handle and celebrity id for each celebrity in namelist
for (i in 1:length(namelist)){
  if (i == 1){
    statement <- paste("select celebrityid, fullname, twitterhandle from celebrity where fullname = ",paste0("'",namelist[1], "'"),"AND isdeleted = 0",';')
    celeb_list <- data.frame(dbGetQuery(con,statement))
    
  }else{
    statement <- paste("select celebrityid, fullname, twitterhandle from celebrity where fullname = ",paste0("'",namelist[i], "'"),"AND isdeleted = 0",';')
    celeb_list <- rbind(celeb_list, dbGetQuery(con,statement))
  }
  
}



#Main loop for running scraper functions
for (i in 1:nrow(celeb_list)){
  #update the monitor to load data for desired celebrities
  update_monitor(celeb_list$fullname[i], celeb_list$twitterhandle[i], update_url)
  #sleep for a random number of secconds between 15-20 secconds
  Sys.sleep(sample(15:20, 1))
  #check if the data has fully loaded on Chrimson Sentiment Monitor
  check_update_status()

  if (sentiment_data_scrape == T){
    
    write.csv(scrape_sentiment_data(celeb_list$celebrityid[i], celeb_list$fullname[i], sentiment_url)
              , paste0('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_sentiment_scrape/', celeb_list$celebrityid[i],'_',celeb_list$fullname[i],'_Sentiment.csv',sep ='')
              , row.names = F)  
    cat(paste0('\nfinished sentiment scrape for:  ', celeb_list$fullname[i]))
    print(Sys.time())
  }
  if (emotion_data_scrape == T){
    
    write.csv( scrape_emotion_data(celeb_list$celebrityid[i], celeb_list$fullname[i], emotion_url)
               , paste0('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_emotion_scrape/scraped_emotion_data_',celeb_list$fullname[i],'.csv',sep ='')
               , row.names = F)  
    cat(paste0('\nfinished emotion scrape for:  ', celeb_list$fullname[i]))
    print(Sys.time())
  }
  if (demographic_data_scrape == T){
    
    write.csv(scrape_demographic_data(celeb_list$celebrityid[i], celeb_list$fullname[i], demographic_url)
              , paste0('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_demographic_scrape/scraped_demographic_data_',celeb_list$fullname[i],'.csv',sep ='')
              , row.names = F)  
    cat(paste0('\nfinished demographic scrape for:  ', celeb_list$fullname[i]))
    print(Sys.time())
  }
  if (geography_data_scrape == T){
    
    write.csv(scrape_geographic_data(celeb_list$celebrityid[i], celeb_list$fullname[i], geographic_url)
              , paste0('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_geographic_scrape/scraped_geographic_data_',celeb_list$fullname[i],'.csv',sep ='')
              , row.names = F)  
    cat(paste0('\nfinished geographic scrape for:  ', celeb_list$fullname[i]))
    print(Sys.time())
  }
  
  #sleep for a random ammount of time between 70 and 100 secconds after each loop 
  Sys.sleep(sample(70:100, 1))
}
