############################
#Selenium functions for crimson
##############################

#function that refreshes monitor page
refresh_page <- function(){
  remDr$refresh()
}


###########
#UPDATE !!! - add a if/else statement to let the user know that they have correctly logged in . if fail, automatically close the browser session and prompt the user to reopen 
#########

#log-in to Crimson Hexagon 
#input: login url, username, and password 
#change inputs from run_scraper_funcitons.R
login <- function(url, username, password){
  
  remDr$navigate(url)
  Sys.sleep(1)
  #fill in user name
  user <- remDr$findElement(using = "id", value = "emailAddress")
  user$clearElement()
  user$sendKeysToElement(list(username))
  Sys.sleep(1)
  
  #click "next" button
  webElem <- remDr$findElement(using = 'id',"next")
  webElem$submitElement()
  Sys.sleep(1)
  
  #fill in password
  pass <- remDr$findElement(using = "id", value = "password")
  pass$clearElement()
  pass$sendKeysToElement(list(password))
  Sys.sleep(1)
  
  
  #click "login" button
  webElem <- remDr$findElement(using = 'css selector',"#loginStep2 > form > fieldset > button")
  webElem$submitElement()#needs to be a few second wait from this point
  
}

#function that updates crimson hexagon Buzz Monitor for each unique celebrity
#input: celebrity name, celebrity twitter handle, and reset page url
update_monitor <- function(celeb_name, celeb_twitter_handle, update_url){
  
  #navigate to editing dashboard
  remDr$navigate(update_url)
  Sys.sleep(sample(3:4,1))
  
  if (celeb_twitter_handle == as.character(gsub(' ', '', celeb_name))){
    updated_string <- paste(paste0('"',celeb_name,'"'),celeb_twitter_handle)
    
  }else{
    updated_string <- paste(paste0('"',celeb_name,'"'),celeb_twitter_handle, as.character(gsub(' ', '', celeb_name)))
    
  }
  #change celebrity name and twitter handle
  webElem <- remDr$findElement(using = 'css selector',"#keyword-selector-oredTerms")
  webElem$clearElement()
  webElem$sendKeysToElement(list(updated_string))
  Sys.sleep(sample(1:2,1))
  #save changes
  webElem <- remDr$findElement(using = 'css selector',"#button-save")
  webElem$clickElement()
  Sys.sleep(2)
  
  #access reset monitor
  webElem <- remDr$findElement(using = 'css selector',"#button-save-reset")
  webElem$clickElement()
  Sys.sleep(4)
  
  #reset newly changed monitor
  webElem <- remDr$findElement(using = 'css selector',"#resetMonitor")
  webElem$clickElement()
  Sys.sleep(3)
  
  #accept google auto alert
  remDr$acceptAlert()
}

#can only use right after updating monitor
#function does not take any inputs. This function ensures the monitor is 
#100 percent loaded before we start scraping sentiment data

# check_update_status <- function(){
#   Sys.sleep(sample(40:50,1))
#   webElem <- remDr$findElement(using = 'css selector',"#monitorSummary > div.status-message.status-information > div.status-message-text > div.info > span")
#   percent_done <- webElem$getElementText()
#   while (!percent_done =='99% done'){
#     webElem <- remDr$findElement(using = 'css selector',"#monitorSummary > div.status-message.status-information > div.status-message-text > div.info > span")
#     percent_done <- webElem$getElementText()
#     refresh_page()
#     Sys.sleep(sample(10:15,1))
#   }
#   Sys.sleep(sample(40:50,1))
#   refresh_page()
# }

#can only use right after updating monitor
check_update_status <- function(){
  start_time <- Sys.time()
  cur_time <- Sys.time()
  Sys.sleep(sample(40:50,1))
  exit_while_loop <- remDr$findElement(using = 'css selector',"#monitorSummary > div.status-message.status-information > div.status-message-text > div.info > span")$getStatus()$message
  #While loop breaks only when the html for the generation status banner is inactive or elapsed time is greater than 10 minutes, whichever comes first
  while (exit_while_loop == 'Server is running'){
    suppressMessages({
      exit_while_loop <- tryCatch({remDr$findElement(using = 'css selector',"#monitorSummary > div.status-message.status-information > div.status-message-text > div.info > span")$getStatus()$message},error=function(e){return('Server is not running')})
    })
    refresh_page()
    Sys.sleep(sample(10:15,1))
    cur_time <- Sys.time()
  }
  Sys.sleep(sample(40:50,1))
  refresh_page()
}

#format scrapped sentiment html to dataset
#input: the html output of the sentiment data scraped by sentiment_dataScrape.R
#output: formatted dataset containing sentiment date, basic positive sentiment, basic neutral sentiment, and basic negative sentiment
format_sentiment_html <- function(html){
  html <- strsplit(html, 'td')
  html <- unlist(html)
  html <- html[seq_along(html) %% 2 == 0]
  date <- (html[seq(1, length(html), 3)])
  percent <- (html[seq(2, length(html), 3)])
  basic_sentiment_volume <- (html[seq(3, length(html), 3)])
  data_set <- cbind(date,percent,basic_sentiment_volume)
  data_set <- data.frame(data_set)
  data_set$date <-  gsub('.*>\\s*|</.*', "", data_set$date)
  data_set$percent <-  gsub('.*class="number">\\s*|</.*', "", data_set$percent)
  data_set$basic_sentiment_volume <-  gsub('.*class="number">\\s*|</.*', "", data_set$basic_sentiment_volume)
  
  data_set$date <- as.POSIXct(data_set$date,format = "%m/%d/%Y")
  data_set$basic_sentiment_volume <- as.integer(data_set$basic_sentiment_volume)
  data_set$percent <- as.numeric(sub("%", "", data_set$percent))/100
  return(data_set)
}

#function that pulls desired monitor's url for automation 
get_monitor_url <- function(monitor_names){
  #navigate to monitors page
  remDr$navigate("https://forsight.crimsonhexagon.com/ch/monitors")
  
  #pull list of monitor names that currently exist on Crimson Hexagon account
  webElem <- remDr$findElement(using = 'css selector',"#DXContent > div.right.dx-right-column > div.dx")
  monitor_list <- webElem$getElementAttribute("outerHTML")[[1]] 
  monitor_list <- strsplit(monitor_list, 'monitorName')
  monitor_urls <- as.character()
  #iterate through each monitor name to find desired automation monitor
  for (i in 1:length(monitor_names)){
    for (j in 2:length(monitor_list[[1]])){
      string_to_format <-  strsplit(monitor_list[[1]][j],'data-ch-name=')
      string_to_format <- string_to_format[[1]][1]
      string_to_format <-  strsplit(string_to_format,'</a>')
      
      formatted_name <-  strsplit(string_to_format[[1]][1],'>')
      formatted_name <- formatted_name[[1]][2]
      monitor_id <- strsplit(string_to_format[[1]][3],'data-id=\"')
      monitor_id <- gsub("\\D", "", monitor_id[[1]][2])
      #if the pulled monitor name equals the desired monitor name, then construct the monitor url using respective monitor_id
      if (formatted_name == monitor_names[i]){
        monitor_urls <- c(monitor_urls, paste0('https://forsight.crimsonhexagon.com/ch/opinion/results?id=', monitor_id))
      }
    }
  }
  return(monitor_urls)
}


#function that gets monitor reset url (must pull update url before sentiment url!)
get_update_url <- function(){
  #click on reset monitor button from monitor home page
  webElem <- remDr$findElement(using = 'id',"editMonitorButton")
  webElem$clickElement()
  #pull current url
  update_url <- remDr$getCurrentUrl()
  return(update_url)
}

#get the sentiment url with filter that's already applied
get_sentiment_url_filtered <- function(){
  #click on filter dropdown menu
  webElem <- remDr$findElement(using = 'css selector',"#globalFilters > div > div:nth-child(3)")
  webElem$clickElement()
  #click on correct filter to apply on dropdown menu
  webElem <- remDr$findElement(using = 'css selector',"  #savedFilters > form > ul > li > h3 > span.name")
  webElem$clickElement()
  #click on sentiment tab to navigate to sentiment data
  webElem <- remDr$findElement(using = 'css selector',"#navLinkanalysis > div > span")
  webElem$clickElement()
  Sys.sleep(sample(2:4,1))
  
  #click on granulation filter for sentiment-by-day data
  webElem <- remDr$findElement(using = 'css selector',"#moduleOpinionAnalysis > div.module-content > div.chart-menus > div:nth-child(2) > ul > li:nth-child(2)")
  webElem$clickElement()
  
  #click on calander dropdown menue 
  webElem <- remDr$findElement(using = 'css selector',"#dateRangeSelected")
  webElem$clickElement()
  #click on 'all time' button in-order to extract all sentiment data
  webElem <- remDr$findElement(using = 'css selector',"#dateOptions > ul:nth-child(3) > li > a")
  webElem$clickElement()
  
  #pull current url
  filtered_sentiment_url <- remDr$getCurrentUrl()
  return(filtered_sentiment_url)
}

get_monitor_status <- function(url){
  remDr$navigate(url)
  webElem <- remDr$findElement(using = 'css selector',"#monitorSetup > div:nth-child(1) > div > div.monitor-status")
  status <- as.character(unlist(webElem$getElementText()))
  return(status)
}

reset_scraper <- function(monitor_number){
  remDr$navigate(monitor_urls[monitor_number])
  
  #get monitor reset url
  update_url <<-  unlist(get_update_url())
  remDr$navigate(monitor_urls[monitor_number])
  #get sentiment url with daily granularity and "-(RT)" filter applied
  sentiment_url <<- unlist(get_sentiment_url_filtered())
}
