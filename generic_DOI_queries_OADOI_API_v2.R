#this script uses the OADOI API to get information on online availability (gold, hybrid, bronze and green Open Access) 
#of sets academic articles retrieved from a list of DOIs. 
#OADOI API information: https://oadoi.org/api and https://oadoi.org/api/v2
#OAIDOI documentation: https://oadoi.org/about


#install packages
install.packages("rjson")
install.packages("httpcache")
require(rjson)
require(httpcache)

#declare variables for specific batch
entity <- "Chili"
year <- "2018"
category <- "all"

#import csv with DOIs; csv should contain list of doi's in column labeled "DOI"
DOI_input <- read.csv(file="xxx.csv", header=TRUE, sep=",")
#row count, declare to variable
DOI_inputCount <- nrow(DOI_input)


#create empty dataframe with 12 columns
df <- data.frame(matrix(nrow = 1, ncol = 7))
#set column names of dataframe
colnames(df) = c("DOI", "data_standard", "is_oa", "host_type", "license", "journal_is_oa", "URL")

#define function to accommodate NULL results
naIfNull <- function(cell){
  if(is.null(cell)) {
    return(NA)
  } else {
    return(cell)
  }
}

#define function to get data from OADOI API and construct vector with relevant variables;
#this vector will become a row in the final dataframe to be produced;
#define doi.character as character for doi to be included as such in the vector;
#employ naIfNull function because not all values are always present in OADOI output.
getData <- function(doi){
  doi_character <- as.character(doi)
  #enter your email address in the line below (replace your@email.com), this helps OADOI contact you if something is wrong
  url <- paste("https://api.oadoi.org/v2/",doi,"?email=bianca.kramer@gmail.com",sep="")
  raw_data <- GET(url)
  rd <- httr::content(raw_data)
  first_result <- rd
  best_location <- rd$best_oa_location
  result <- c(
    doi_character,
    naIfNull(first_result$data_standard),
    naIfNull(first_result$is_oa),
    naIfNull(best_location$host_type),
    naIfNull(best_location$license),
    naIfNull(first_result$journal_is_oa),
    naIfNull(best_location$url)
    )
  return(result)
}


#fill dataframe df (from 2nd row onwards) with API results for each DOI from original dataset
#escape errors to jump any rows giving a 404 in API call
for (i in 1:DOI_inputCount){
#can also use line below to set counter manually for batches of e.g. 500
#for (i in 1:500){
  tryCatch({
  df <- rbind(df,getData(DOI_input$DOI[i]))
  }, error=function(e){})
}


#analyze results to count green, gold, hybrid, bronze, NA
#number of DOIs retrieved
numberDOI <- sum(!is.na(df$DOI))
#number of occasions with datastandard 2 (better for hybrid)
numberDataStandard2 <- sum(df$data_standard == 2, na.rm=TRUE)
#number of articles available OA
df_OA <- subset(df, is_oa == TRUE)
numberOA <- nrow(df_OA)
#number of articles available OA from publisher (= gold in WoS)
df_allGold <- subset(df_OA, host_type=="publisher")
number_allGold <- nrow(df_allGold)
#number of green OA (if any)
df_Green <- subset (df_OA, !host_type=="publisher")
numberGreen <- nrow(df_Green)
#number of gold (= in DOAJ)
df_Gold <- subset(df_allGold, journal_is_oa==TRUE)
numberGold <- nrow(df_Gold)
#number of hybrid (= not in DOAJ, but with license)
df_Hybrid <- subset(df_allGold, !journal_is_oa==TRUE &  !is.na(license))
numberHybrid <- nrow(df_Hybrid)
#number of Bronze (= not in DOAJ, no license)
df_Bronze <- subset(df_allGold, !journal_is_oa==TRUE &  is.na(license))
numberBronze <- nrow(df_Bronze)

#calculate percentages
percentRetrieved <- round(numberDOI/DOI_inputCount, digits=3)*100
percentOA <- round(numberOA/numberDOI, digits=3)*100
percentWoSGold <- round(number_allGold/numberOA, digits=3)*100
percentGreen <- round(numberGreen/numberOA, digits=3)*100
percentGold <- round(numberGold/number_allGold, digits=3)*100
percentHybrid <- round(numberHybrid/number_allGold, digits=3)*100
percentBronze <- round(numberBronze/number_allGold, digits=3)*100

#print summary
cat(entity, year, category,
    "\n",DOI_inputCount,"checked",
    "\n", numberDOI,"retrieved -", percentRetrieved, "%",  
    "\n", numberOA, "OA -", percentOA, "%",
    "\n", number_allGold, "WoS gold -", percentWoSGold, "%",
    "\n", numberGreen, "green - ", percentGreen, "%",
    "\n", numberGold, "gold (in WoS gold) - ", percentGold, "%",
    "\n", numberHybrid, "hybrid (in WoS gold) -", percentHybrid, "%",
    "\n", numberBronze, "bronze (in WoS gold) -", percentBronze, "%",
    "\n", "[check] gold+hybrid+bronze (in WoS gold) - ", percentGold+percentHybrid+percentBronze, "%")

#declare file name
fileOADOI <- paste("OADOI_",entity,"_",year,"_",category,".csv",sep="")
#write DOI-list from WoS to file
write.csv(df, file=fileOADOI, row.names=FALSE)