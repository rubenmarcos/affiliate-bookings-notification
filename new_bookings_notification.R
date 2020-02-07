library(rvest)
library(jsonlite)
library(dplyr)
library(zoo)
library(mime)
library(gmailr)


# Reference dates

today <- as.Date(Sys.Date())
yesterday <- as.Date(Sys.Date()-1)


# CONNECT - RVEST --------------------------------------------------------------------


# Connecting to the performance dashboard
# Include your own user name and password


url       <-"https://admin.booking.com/partner"
pgsession <-html_session(url)

login <- pgsession %>% 
  html_node("form") %>% 
  html_form() %>%
  set_values(loginname = "your_user_name", password = "your_password") 

login$url <- ''

session <- submit_form(pgsession,login)


# EXTRACT - TIDYVERSE AND JSONLITE --------------------------------------------------------------------
# Some basic navigation to find the URL we need to acceed in order to download the data.

text <- follow_link(session,xpath = "/html/body/div[1]/nav/div/ul/li[4]/ul/li[3]/a") %>% read_html() %>% html_node("table") %>% xml_find_all("//*[@class='clearfix']/a")

text_2 <- xml_attrs(text[[2]])[['href']] 


# You just need the first part of the URL, so find your affiliate id number and delete everything after that.
# Then, paste it again and add the date parametres you need for downloading relevant information.

text_2 <- gsub("-your_affiliate_id-.*","",text_2)

text_2 <- paste0(text_2,"-your_affiliate_id-&preformat_table=1&date=",yesterday,"&end_date=",today)


# Navigate and download those results.
# Results come from a JSON file, so we need to extract and transform JSON data.

text_3 <- jump_to(session,text_2)

text_4 <- fromJSON(as.character(text_3[["response"]]))[["data"]] 


# Clean results in order to get only the information you need

text_4 <- text_4 %>% select(created, hotel_name, hotel_city, hotel_country, Commission = aff_fee_euro, checkin, checkout, length_of_stay, label, user_device) %>% mutate(created = as.POSIXct(created), Commission = as.numeric(Commission), checkin = as.Date(checkin), checkout = as.Date(checkout), user_device = as.character(user_device))

# The key part of the update is comparing a previous data frame against a new one and extract the differences to a new one.
# If there is a previous file, the script does it automatically
# But if we are using it for the first time or want to restart the whole process, we need a new one. This commented line makes the trick
# Uncomment and execute on the first use for creating the first base of comparisons. Comment again after first use.

# write.csv(data.frame("created" = "", "hotel_name" = "", "hotel_city" = "", "hotel_country" = "", "Commission" = "", "checkin" = "", "checkout" = "", "length_of_stay" = "", "label" = "", user_device = ""), "results-A.csv", row.names = FALSE)


# Upload previous data frame available, compare it with the new one and create a new data frame for the differences.

previous <- read.csv("results-A.csv", encoding = "UTF-8", stringsAsFactors = FALSE) %>% mutate(created = as.POSIXct(created), Commission = as.numeric(Commission), checkin = as.Date(checkin), checkout = as.Date(checkout), hotel_name = as.character(hotel_name), hotel_city = as.character(hotel_city), hotel_country = as.character(hotel_country), length_of_stay = as.numeric(length_of_stay), label = ifelse(is.na(as.character(label)),"",as.character(label)), user_device = as.character(user_device))

new_results <- setdiff(text_4,previous)


# Store the new data frame for using it on the next comparison as previous dataset.

write.csv(text_4, "results-A.csv", row.names = FALSE)



# NOTIFY - GMAIL --------------------------------------------------------------------

# Configuring was a pain in the ass, but once you have it done and get the tokens, you can use it for any other project.
# This script was intended to be automatised with cronr, so if you are using it on other circumstances, you may need to make some changes to the gm_auth options.


# Configure your app based on the JSON file obtained from Google APIs console.
# Create and OAuth 2.0 Client IDs on the Credentials section on https://console.developers.google.com/ and download the file.
# Gmail API has to be enabled. Find it on the Library section on the left menu.

gm_auth_configure(path = "json_file_from_google_apis.json")


# Saving a token on RDS format and storing it on the server may be one of the easiest way to automatize the process. Example:
# token <- gm_auth()
# saveRDS(token, file = "stored_token.rds")

gm_auth(token = readRDS("stored_token.rds"), email = "yout_email@gmail.com", use_oob = TRUE)


# Send an e-mail only if there are new bookings.
# A loop creates a basic HTML code for each record, stored in a column of the data frame

if (dim(new_results)[2] == 0) {
  
} else {
  
  for (i in 1:nrow(new_results)) {
    
    new_results$mail[i] <- paste0("<p style='font-size:12px;'>Date: ",new_results$created[i],"<br>Country: ",new_results$hotel_country[i],"<br>City: ",new_results$hotel_city[i],"<br>Hotel: ",new_results$hotel_name[i],"<br>Check-in: ",new_results$checkin[i],"<br>Check-out: ",new_results$checkout[i],"<br>Length of Stay: ",new_results$length_of_stay[i],"<br>Commission: ",new_results$Commission[i],"<br>Device: ",new_results$user_device[i],"<br>Label: ",new_results$label[i],"</p>")
    
  }
  
  # Paste all the registers on the HTML column on a single e-mail template and send the e-mail
  
  mail_results <- paste(new_results$mail, collapse = " ")
  
  body_mail <- paste0("<p>New Bookings: </p>",mail_results)
  
  update_email <- gm_mime() %>% gm_to("destination_address@domain.com") %>% gm_from("New Bookings <origin_address@gmail.com>") %>% gm_subject("New Bookings Notification") %>% gm_html_body(body_mail)
  gm_send_message(update_email)
  
} 
