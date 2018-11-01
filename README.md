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
1. Create local credential csv containing login credentials for crimson hexagon: An example of this file is under crimson_credentials.csv

## Connecting to Remote Chrome Server
* **Step 1:** Open your machine's Command Prompt and navigate to RSelenium package/bin directory. Example: cd C:/Users/pete/OneDrive/Documents/R/win-library/3.5/RSelenium/bin  (NOTE: its important that you provide your machine's RSelenium bin file path.)
* **Step 2:** By default the Selenium Server listens for connections on port 4444 which is most likely being used for your default browser. So, you must specify which port to start your selenium session on. In the compand prompt again, run: 
java -DwebDriver.chrome.driver="C:Users\Pete\Downloads\chromedriver.exe" -jar selenium-server-standalone-3.14.0.jar -port 4445
 (NOTE: its important that you provide your machine's executable chromedriver file path.)
* **Step 3:** Run Docker Toolbox to configure remote session default IP.
* **Step 4:** Go to the R terminal and run: docker run -d -p 4445:4444 selenium/standalone-chrome to connect remote server to current R session.
* **Step 5** Update celeb_list.csv with proper id's to be able to scrape sentiment data for the celebrities of interest.
* **Step 6:** Hit Source on run_scraper_functions.R  and the scraper should take care of the rest.
* **Step 7:** Look out for monitor output such as 'You have sucessfully logged in!' and 'finished sentiment scrape for:  celebrity_name' as indicators of successfully running the scraper.
