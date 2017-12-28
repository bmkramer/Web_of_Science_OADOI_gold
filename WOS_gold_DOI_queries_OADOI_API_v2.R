#this script uses the OADOI API to get information on online availability (gold, hybrid, bronze and green Open Access) 
#of sets of academic articles retrieved from Web of Science. 
#OADOI API information: https://oadoi.org/api and https://oadoi.org/api/v2
#OAIDOI documentation: https://oadoi.org/about
#reading WoS data: https://github.com/alberto-martin/read.wos.R/blob/master/report.Rmd

#install packages
#install.packages("rjson")
#install.packages("httpcache")
#install.packages("data.table")
#require(rjson)
#require(httpcache)
#require(data.table)


#declare variables for specific batch
#enter your own values here
entity <- "Utrecht"
year <- "2016"
category <- "gold"


#define and execute function to parse a list of WoS export files in Tab-delimited (Win, UTF-8) format, 
#and convert them to a data.table.
#WoS export files should be placed in folder "WoS_export" in working directory

#declare variable for WoS output fields
fields <- c('PT', 'AU', 'BA', 'BE', 'GP', 'AF', 'BF', 'CA', 'TI', 'SO', 'SE', 'BS', 
            'LA', 'DT', 'CT', 'CY', 'CL', 'SP', 'HO', 'DE', 'ID', 'AB', 'C1', 'RP', 
            'EM', 'RI', 'OI', 'FU', 'FX', 'CR', 'NR', 'TC', 'Z9', 'U1', 'U2', 'PU', 
            'PI', 'PA', 'SN', 'EI', 'BN', 'J9', 'JI', 'PD', 'PY', 'VL', 'IS', 'PN', 
            'SU', 'SI', 'MA', 'BP', 'EP', 'AR', 'DI', 'D2', 'EA', 'EY', 'PG', 'WC', 
            'SC', 'GA', 'UT', 'PM', 'OA', 'HC', 'HP', 'DA', 'AA', 'BB')


#function to import Wos data from tab-delimited format (Win, UTF-8)
read.wos.tw8 <- function(path = './files', nrows=1000000L) {
  # reads list of files
  files  <- list.files(path)  
  
  # creates empty data.table
  dt <- data.table(x=rep('0',nrows))
  l  <- list(rep("0",length(fields)))
  i  <- 1
  for (field in fields) {
    l[[i]] <- rep('0',nrows)
    i <- i + 1
  }
  dt[, fields := l, with = FALSE]
  dt[,x:=NULL]
  
  i  <- 1L # row counter
  # Iterates through all files in path
  for (file in files) {
    # reads a file, and saves its lines as a character vector
    fullpath  <- paste(path,'/',file, sep='')
    lines  <- readLines(fullpath)
    lines <- lines[2:length(lines)]
    
    for (line in lines) {
      # Splits each row into a character vector, and updates the rows in the data.table
      row <- strsplit(line, '\t')[[1]][1:length(fields)]
      j  <- 1L # column counter
      for (field_value in row) {
        # Converts empty fields to NA
        if (field_value == "" | is.na(field_value)) {
          field_value  <- NA
        }
        set(dt,i,j,field_value)
        j  <- j + 1L
      }
      i  <- i + 1L
    }
  }
  # deletes unused rows and columns
  dt <- dt[PT != '0']
  dt <- dt[,AA:=NULL]
  dt <- dt[,BB:=NULL]
  
  # converts some variables to integer: NR (number of cited references),
  #                                     TC (times cited WoS),
  #                                     Z9 (total Times Cited Count (WoS, BCI, and CSCD))
  #                                     PY (publication year)
  
  int_fields <- c('NR', 'TC', 'Z9', 'PY')
  for (int_field in int_fields) {
    class(dt[[int_field]]) <- 'integer'
  }
  
  # returns data.table
  dt
}

#read WoS files (warning can be ignored)
WoS_input <- read.wos.tw8('WoS_export')

#convert data.table into regular dataframe
#class(as.data.frame(WoS_input))
#row count, declare to variable
#WoS_inputCount <- nrow(WoS_input)

#subset columns with DOI and OA status
#some approaches cause issue with data.table, this one seems to work
cols<-(colnames(WoS_input) %in% c("DI","OA"))
#double comma needed in line below, gives error otherwise
DOI_input <-subset(WoS_input,,cols)

#keep only rows with DOI
DOI_input <- na.omit(DOI_input)
#row count, declare to variable
DOI_inputCount <- nrow(DOI_input)

#rename column heading DI to DOI
names(DOI_input)[1] <- "DOI"

#declare file name
fileDOI <- paste("WoS_DOI_",entity,"_",year,"_",category,".csv",sep="")
#write DOI-list from WoS to file
write.csv(DOI_input, file=fileDOI, row.names=FALSE)


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
  url <- paste("https://api.oadoi.org/v2/",doi,"?email=your@email.com",sep="")
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
#excape errors to jump any rows giving a 404 in API call
for (i in 1:DOI_inputCount){
  tryCatch({
  df <- rbind(df,getData(DOI_input$DOI[i]))
  }, error=function(e){})
}


#analyze results to count gold, hybrid, bronze, NA
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
df_Green <- subset (df_OA, host_type=="repository")
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
    "\n", numberGold, "gold - ", percentGold, "% (in WoS gold)",
    "\n", numberHybrid, "hybrid -", percentHybrid, "% (in WoS gold)",
    "\n", numberBronze, "bronze -", percentBronze, "% (in WoS gold)",
    "\n", "[check] gold+hybrid+bronze (in WoS gold) - ", percentGold+percentHybrid+percentBronze, "%")

#declare file name
fileOADOI <- paste("OADOI_",entity,"_",year,"_",category,".csv",sep="")
#write DOI-list from WoS to file
write.csv(df, file=fileOADOI, row.names=FALSE)