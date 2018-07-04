# ronantime
R code for bot that tweets at https://twitter.com/ronant1m3

This code polls Ronan Farrow's author page at The New Yorker (https://www.newyorker.com/contributors/ronan-farrow), and tweets when there is a new article.

Install and Setup Guidance:

The info below is designed for an Linux/Ubuntu setup. It can likely be adpated with little change for MacOS as well.

R prerequisite libraries: rvest, rtweet, lubridate, plyr, dplyr

Save the R code to a directory. i.e., /Users/rfarrow_bot/rfarrow_bot.R

1. Edit the lines at the top of the code under the "USER CONFIGURABLE INPUT PARAMETERS" section This is done as follows:

1a. Directories: Pick whatever works for you. A suggested structure and notes are listed in the code comments.
1b. Filename: For the file that will be saved and used for comparison to check for new articles, what do you want the name to be.
1c. Author String: List the author URL on The New Yorker. For Ronan Farrow, the full URL is https://www.newyorker.com/contributors/ronan-farrow. Just list the "ronan-farrow" portion here.
1d. Bot Tweet: What do you want the early porton of the tweet to say when the bot tweets.
1e. Twitter token: If you do not have an rtweet twitter token, the method for obtaining and saving one is here: http://rtweet.info/articles/auth.html

2. Save and rename the provided initial .csv file to the main_dir. This should be consistent with the file naming above. i.e., so if we picked "rfarrow" above, we should ensure the file name is named rfarrow.csv.

3. Create an empty file where errors can be logged. The file must be in the main_dir and must be specifically named std_msgs.txt (Linux/Ubuntu command to do this: touch std_msgs.txt)

4. At this time, if you run the code, it will populate the file and generate tweets for the articles since the initial .csv was generated (July 3, 2018).

5. If you want to continue polling and tweeting, schedule as needed with crontab (or other scheduling tool). Suggested run frequency is every 5-10 minutes.
