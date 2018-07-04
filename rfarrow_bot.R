#
#  THE NEW YORKER SCRAPER
#  THIS WILL FETCH AND POPULATE A DB TABLE FOR
#  ARTICLES BY THE SPECIFIED AUTHORS
#  

#  START TIME AND LOAD LIBRARIES

library(rvest)
library(rtweet)
library(lubridate)
library(plyr)
library(dplyr)

Sys.setenv(TZ='America/New_York')
tnystarttime <- proc.time()

#  USER CONFIGURABLE INPUT PARAMETERS

# Edit these  lines for the respective directory locations
# It is suggested to make backups as subdirectories of the main_dir
# i.e., bkup_dir = /main_dir/backups/
# Note - you must include the trailing slash and you must leave the quotation marks
main_dir <- "INSERT MAIN DIRECTORY NAME HERE"
bkup_dir <- "INSERT BACKUP STORAGE DIRECTORY NAME HERE"

# For the file that will be saved and used for comparison to check for new articles
# what should the name be. In this case, we are using "rfarrow". The code will take care of adding
# any necessary extensions (i.e., "rfarrow.csv")
filename_header <- "rfarrow"

# List the author URL on The New Yorker. For Ronan Farrow, the full URL is 
# https://www.newyorker.com/contributors/ronan-farrow. We just need to list the "ronan-farrow" portion here
# The code will take care of the rest.
authorstring = "ronan-farrow"

# What do you want the bot to say when it tweets. In this case, we are using "It's #RonanTime"
whattimeisit = "#RonanTime"

# Replace "INSERT YOUR TWITTER TOKEN FILENAME" with your twitter token file name
# As noted below, it is suggested to place this file in the main_dir
# See http://rtweet.info/articles/auth.html on how to create this twitter token
# You must leave the quotation marks and list your filename within those
twitter_token <- readRDS(paste0(main_dir,"INSERT YOUR TWITTER TOKEN FILENAME"))


###  NOTHING BELOW THIS SHOULD NEED TO GET EDITED ###

tny_file <- paste0(main_dir,filename_header,".csv")
tny_file_bkup <- paste0(bkup_dir,filename_header,"_",format(Sys.time(), "%Y%m%d_%H%M%S"),".csv")
tny_file_csv <- read.csv(tny_file, header = TRUE, sep = ",", check.names=FALSE, stringsAsFactors = FALSE)

sink_msgs <- file(paste0(main_dir,"std_msgs.txt"), open="at")
sink(sink_msgs,type=c("message"),append = TRUE)
sink(sink_msgs,type=c("output"),append = TRUE)

#  INITIALIZATIONS AND LINK SCRAPE

tweet_max <- 275
tny_file_csv$pub_date <- ymd(tny_file_csv$pub_date)
tny_df0 <- tny_file_csv

tnypage=read_html(paste0("https://www.newyorker.com/contributors/",authorstring))

tnymain <- tnypage %>% html_nodes(xpath="//div[contains(@class,'River__recentWork')]") %>% html_nodes(xpath="//div[contains(@class,'River__riverItemContent')]")
tnysub <- tnymain %>% html_nodes(xpath="//div[contains(@class,'River__riverItemBody')]") 

tny_url_base <- sapply(tnysub,function(x) x %>% html_nodes("a") %>% `[[`(1) %>% html_attr("href"))
tny_df <- data.frame("url_base" = tny_url_base,stringsAsFactors = FALSE)

tny_df <- tny_df %>% mutate(
  headline = sapply(tnymain,function(x) x %>% html_nodes("a") %>% html_nodes("h4") %>% html_text),
  description = sapply(tnysub,function(x) x %>% html_nodes("h5") %>% html_text),
  fulllink = paste0("https://www.newyorker.com",tny_df$url_base),
  tweet_text = paste0("It's ",whattimeisit,": ",headline,"\n",fulllink),
  num_char = nchar(tweet_text))

tny_df$tweet_text <- 
  ifelse(tny_df$num_char > tweet_max,
         paste0("It's ",whattimeisit,": ",strtrim(tny_df$headline,nchar(tny_df$headline)-(tny_df$num_char-tweet_max-3)),"...\n",tny_df$fulllink),
         tny_df$tweet_text)

for (tnyidx in 1:nrow(tny_df)) {
  tny_df$pub_date[tnyidx] = 
    ifelse (length(tnysub[[tnyidx]] %>% html_nodes("h6") %>% html_text)!=0,
            mdy(tnysub[[tnyidx]] %>% html_nodes("h6") %>% html_text),
            ifelse (!grepl("&",tnymain[[tnyidx]] %>% html_nodes("time") %>% html_text),
                    mdy(trimws(gsub("Issue","",tnymain[[tnyidx]] %>% html_nodes("time") %>% html_text))),
                    mdy(gsub("\\s&\\s\\d*","",trimws(gsub("Issue","",tnymain[[tnyidx]] %>% html_nodes("time") %>% html_text))))))
}

class(tny_df$pub_date) <- "Date"

#  COMPARISONS AND DIFF

tny_df0 <- tny_df0[order(tny_df0$pub_date),]
tny_df <- tny_df[order(tny_df$pub_date),]

tny_diff <- anti_join(tny_df,tny_df0,by = c("fulllink"))

if (nrow(tny_diff)>0) {
  for(tnytidx in 1:nrow(tny_diff)) {
    post_tweet(status = tny_diff$tweet_text[tnytidx],token = twitter_token)
  }
}

if(nrow(tny_diff)>0){
  tny_df0 <- tny_df0[order(tny_df0$pub_date,decreasing = TRUE),]
  write.csv(tny_df0,file = tny_file_bkup,row.names=FALSE)
  
  tny_df <- tny_df[order(tny_df$pub_date,decreasing = TRUE),]
  write.csv(tny_df,file = tny_file,row.names=FALSE)
}

# FINAL TIME TO RUN CALCULATION

tnyendtime <- proc.time() - tnystarttime
tnyendsecs <- tnyendtime[3]
print(tnyendsecs)
print(Sys.time())
cat("\n\n")

sink(type="message")
sink(type="output")
close(sink_msgs)