# Crimson-Hexagon-Scraper

## Install RSelenium
To install [`RSelenium`](https://cran.r-project.org/web/packages/RSelenium/RSelenium.pdf) from CRAN, run:

```R
install.packages("RSelenium")
```

To install the development version from GitHub, run:

```R
# install.packages("devtools")
devtools::install_github("ropensci/RSelenium")
```
To get started using `RSelenium` you can look at:
1. [Basics](http://ropensci.github.io/RSelenium/articles/basics.html)

## Dependencies
Please make sure you have the listed dependencies installed on your machine
1. RSelenium
1. [Docker for Windows](https://docs.docker.com/docker-for-windows/install/) OR [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
1. [Chrome Driver](http://chromedriver.chromium.org/downloads)

## Create Local Credential csv Containing Login Credentials for Crimson Hexagon
An example of this file is under credential.csv

FLUF

#Connecting to Remote Chrome Server
* **Step 1:** open your machine's Command Prompt and navigate to RSelenium package/bin directory. Example: C:/Users/pete/OneDrive/Documents/R/win-library/3.5/RSelenium/bin
* **Step 2:** By default the Selenium Server listens for connections on port 4444 which is most likely being used for your default browser. So, you must specify which port to start your selenium session on. In the compand prompt, after step one, run: 
java -DwebDriver.chrome.driver="C:Users\Pete\Downloads\chromedriver.exe" -jar selenium-server-standalone-3.14.0.jar -port 4445
* **Step 3:** Run Docker Toolbox
* **Step 4:** go to R terminal and run line: docker run -d -p 4445:4444 selenium/standalone-chrome
* **Step 5:** Open R session and replace the 'monitor_name' variable to the name of the monitor you want to scrape
* **Step 6:** Hit Source and the bot should take care of the rest
* **Step 6:** look out for monitor output such as 'You have sucessfully logged in!' and 'finished sentiment scrape for:  celebrity_name' as indicators of successfully running the bot
