# Affiliate Bookings Notifications
R script for receiving custom notifications on your e-mail for new affiliate hotel bookings.

## - Main goal:
Several affiliate programmes notify their partners every time they receive a new booking. When that functionality is not available, the affiliate needs to log in manually on the affiliate site and check the information on a standard basis.

The main goal of this script is help the affiliate to avoid this process and receive a custom notification when there are new bookings. But can be also easily modified to be used under differents circumstances when someone needs to keep track of changes on the contents on any site.

There are four different processes covered by this script: connect to a certain site, extract the required information, compare with a previous version and notify changes (if any).

## - Potential uses:

The main one is helping the affiliate to keep track of new bookings without forcing him to log on the site, in order to take actions according to the bookings received. As an example, a higher amount of booking on certain moment, can encourage the partner to reinforce social media or PPC actions in the short term; or the absence of bookings in a strong period could indicate problems on the site.

But the basics of the script allow other users to take profit of it with mininal changes. Some potential uses could include:

- Price tracking alterts on e-commerce (both as customers or competitors).

- Tracking of status on complex processes when there are not available notifications.

- Follow-up of comments or new posts on certain online contents (like a new review received by a competitor or a comment on a news article about a relevant topic)

## - Requirements:
- R.
- Packages: tidyverse, rvest, httr, jsonlite, zoo, gmailr, mime.
- Affiliate account on the hotel provider.

## - How does it work?:
- Insert your log-in details for the affiliate site.
- Rvest will connect to the site and navigate to the link where the JSON data can be downloaded.
- Jsonlite will transform the data into a data frame format. That data frame will be checked against a previous version. Any changes will be reflected on a new_results data frame.
- Notifying the changes through Gmail requires an oAuth token that can be obtained from https://console.developers.google.com and has to be configured according the instructions of the gmailr package: https://rdrr.io/cran/gmailr/f/README.md
- The script has been tailored to be scheduled through cronr on RStudio Server. If you want to be automatically notified, schedule the execution of the script.
