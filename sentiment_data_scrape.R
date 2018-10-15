#Crimson Hexagon sentiemnt specific scrapper functions


#Function that scrapes positive sentiment.
#input: integer value of html id for positive sentiment table 
pull_basic_positive_sentiment <- function(htmlId){
  tryCatch({
    webElem <- remDr$findElement(using="id", value=as.character(htmlId))
    basic_positive_elemtxt <- webElem$getElementAttribute("outerHTML")[[1]] 
    return(basic_positive_elemtxt)
  }, error = function(cond)
  {
    NA
  })
}

#Function that scrapes neutral sentiment.
#input: integer value of html id for neutral sentiment table 
pull_basic_neutral_elemtxt <- function(htmlId){
  tryCatch({
    webElem <- remDr$findElement(using="id", value=as.character(htmlId))
    basic_neutral_elemtxt <- webElem$getElementAttribute("outerHTML")[[1]] 
    return(basic_neutral_elemtxt)
  }, error = function(cond)
  {
    NA
  })
}

#Function that scrapes negatiev sentiment.
#input: integer value of html id for negative sentiment table 
pull_basic_negative_sentiment <- function(htmlId){
  tryCatch({
    webElem <- remDr$findElement(using="id", value=as.character(htmlId))
    basic_negative_elemtxt <- webElem$getElementAttribute("outerHTML")[[1]] 
    return(basic_negative_elemtxt)
  }, error = function(cond)
  {
    NA
  })
}

#pulls sentiment data table id's for positive, negative, and neutral sentiment. 
#this function does not return anything, just assigns three global vairables 
get_sentiment_ids <- function(){
  remDr$navigate(sentiment_url)
  Sys.sleep(sample(2:4, 1))
  webElem <- remDr$findElement(using="css selector", value="#dataTableByCategory")
  basic_positive_elemtxt <- webElem$getElementAttribute("outerHTML")[[1]] 
  html <- strsplit(basic_positive_elemtxt, '\n\t\t\t\t\t\t<tbody id')
  basic_positive_id <- html[[1]][2]
  basic_neutral_id <- html[[1]][3]
  basic_negative_id <- html[[1]][4]
  
  basic_positive_id <- strsplit(basic_positive_id, 'category group_')
  basic_neutral_id <- strsplit(basic_neutral_id, 'category group_')
  basic_negative_id <- strsplit(basic_negative_id, 'category group_')
  
  basic_positive_id <<-gsub("[^0-9\\.]", "", basic_positive_id[[1]][1])
  basic_neutral_id <<-gsub("[^0-9\\.]", "", basic_neutral_id[[1]][1])
  basic_negative_id <<-gsub("[^0-9\\.]", "", basic_negative_id[[1]][1])
}

#This function calls the three pull functions above to format each html file and create a neat dataset output. 
#inorder to comply with our currently desired format, each dataset output only includes Analysis Date, Basic Positive, Basic Neutral and Basic Negative 
scrape_sentiment_data <- function(celebrityid, fullname, sentiment_url){
  #navigate to dashboard with "-RT" filter already applied
  remDr$navigate(sentiment_url)
  Sys.sleep(5)
  
  #scrape basic positive sentiment volume 
  basic_positive_sentiment <- pull_basic_positive_sentiment(basic_positive_id)
  #scrape basic neutral sentiment volume 
  basic_neutral_sentiment <- pull_basic_neutral_elemtxt(basic_neutral_id)
  #scrape basic negative sentiment volume 
  basic_negative_sentiment <- pull_basic_negative_sentiment(basic_negative_id)
  
  #format scrapped html so that its usable
  basic_positive_sentiment <- format_sentiment_html(basic_positive_sentiment)
  basic_neutral_sentiment <- format_sentiment_html(basic_neutral_sentiment)
  basic_negative_sentiment <- format_sentiment_html(basic_negative_sentiment)
  
  #merge all three datasets
  formatted_data_set <- merge(basic_positive_sentiment,basic_neutral_sentiment, by = 'date')
  formatted_data_set <- merge(formatted_data_set,basic_negative_sentiment, by = 'date')
  
  #rename columns and add on celebrityid column
  colnames(formatted_data_set) <- c('Analysis Date','percent_positive', 'Basic Positive','percent_neutral', 'Basic Neutral','percent_negative', 'Basic Negative')
  #formatted_data_set['celebrityid'] = celebrityid
  #formatted_data_set['fullname'] = fullname
  
  #subset columns to only include what we currently care about
  formatted_data_set <- formatted_data_set[ ,c(1,3,5,7)]
  
  return(formatted_data_set)
}


