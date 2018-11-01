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

#Must make sure that you are using the correct monitor name. Please copy and paste your monitor name
monitor_names <-c('Data_Team-1','Data_Team-2','Data_Team-3','Data_Team-4')

#read in list of celebrity names from preset csv file
celeb_list <- read.csv('C:/Users/pete/OneDrive/Desktop/crimson_selenium/celeb_list.csv')

#set a list of unique celebrity names from your csv containing 
#celebrity names of celebrities you'd like to scrape sentiment data for
id_list <- as.character(unique(celeb_list$celebrityid))

#initialize MySQL connection to spotteddataanalytics database
con <- dbConnect(MySQL(),
                 user="analyticDbAdmin", password="R#E30Dh#ZnWL",
                 dbname="spotteddataanalytics", host="analyticproddb1.cjpwtuibxstb.us-west-2.rds.amazonaws.com")

#Pull celebrity twitter handle and celebrity id for each celebrity in namelist and create dataset containing celebrity id, fullname, and twitterhandel
for (i in 1:length(id_list)){
  if (i == 1){
    statement <- paste("select celebrityid, fullname, twitterhandle from celebrity where celebrityid = ",id_list[1],"AND isdeleted = 0",';')
    celeb_list <- data.frame(dbGetQuery(con,statement))
    
  }else{
    statement <- paste("select celebrityid, fullname, twitterhandle from celebrity where celebrityid = ",id_list[i],"AND isdeleted = 0",';')
    celeb_list <- rbind(celeb_list, dbGetQuery(con,statement))
  }
  
}


#import crimson hexagon username and passwordfrom loacl credential file
crimson_credentials <- read.csv('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_credentials.csv')
#credentials <- read.csv('C:\Users\pete\OneDrive\Desktop\crimson_selenium\credentials.csv')
username <- as.character(crimson_credentials$email)
password <- as.character(crimson_credentials$password)

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
login("https://forsight.crimsonhexagon.com/ch/login", username, password)

#check if successfully logged in
if(remDr$getCurrentUrl() == 'https://forsight.crimsonhexagon.com/ch/home') {
  cat('You have sucessfully logged in!')
} else{
  remDr$close()
  cat('There was an error in your login credentials. Please close the ensure you have entered the correct credentials before rerunning!')
  break
}

#intialize starting and ending indices for scraper
start <-1
end <- nrow(celeb_list)

#get main monitor url
monitor_urls <- get_monitor_url(monitor_names)
monitor_number <- 1


remDr$navigate(monitor_urls[monitor_number])

#get monitor reset url
update_url <-  unlist(get_update_url())
remDr$navigate(monitor_urls[monitor_number])
#get sentiment url with daily granularity and "-(RT)" filter applied
sentiment_url <- unlist(get_sentiment_url_filtered())
get_sentiment_ids()


#Main loop for running scraper functions
for (i in start:end){
  tryCatch({
    #update the monitor to load data for desired celebrities
    update_monitor(celeb_list$fullname[i], celeb_list$twitterhandle[i], update_url)
    #sleep for a random number of secconds between 15-20 secconds
    Sys.sleep(sample(15:20, 1))
    #check if the data has fully loaded on Chrimson Sentiment Monitor
    check_update_status()
    
    if (sentiment_data_scrape == T){
      
      write.csv(scrape_sentiment_data(celeb_list$celebrityid[i], celeb_list$fullname[i], sentiment_url)
                , paste0('C:/Users/pete/OneDrive/Desktop/crimson_selenium/crimson_sentiment_scrape_rerun/', celeb_list$celebrityid[i],'_',celeb_list$fullname[i],'_Sentiment.csv',sep ='')
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
  }, error=function(e){
    Sys.sleep(sample(120:180, 1))
    remDr$close()#close last browsing session
    remDr$open() #initialize chrome browser
    #login to Chrimson Hexagon
    login("https://forsight.crimsonhexagon.com/ch/login", username, password)
    remDr$navigate(monitor_urls[monitor_number])
    monitor_status <- get_monitor_status(update_url)
    if (monitor_number <= 4 & monitor_status=="Status:\nFull results available" | monitor_number <= 4 & monitor_status=="Status:\nGenerating..."){
      start <- i#keep track of last scraped celebrity
      remDr$navigate(monitor_urls[monitor_number])
      reset_scraper(monitor_number)
      get_sentiment_ids()
    }else if(monitor_status=="Status:\nInactive" | monitor_status=="Status:\nNever Run"){
      start <- i#keep track of last scraped celebrity
      monitor_number <- monitor_number + 1
      remDr$navigate(monitor_urls[monitor_number])
      reset_scraper(monitor_number)
      get_sentiment_ids()
    }else{
      remDr$close()
      cat('All monitors are inactive. Please reset all four monitors: Data_Team-1, Data_Team-2, Data_Team-3, and Data_Team-4 and rerun the scraper.')
      cat('Last scraped index was: ',i)
    }
  })
}

