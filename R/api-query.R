old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

instrument <- 'VIIRS'
data_id <- 'VNP10A1F'
data_version <- '1'
format <- 'HDF-EOS5'
time <- '2023-03-10T00:00:00,2023-03-15T12:00:00'
WSEN 
SW <- '43,6'
NE <- '48,14'

curl_call <- 
  glue::glue(
    'curl ',
    '-b .urs_cookies ',
    '-c .urs_cookies ',
    '-L -O ',
    '--netrc-file .netrc ',
    '-J ',
    '--dump-header response-header.txt ',
    '"',
    'https://n5eil02u.ecs.nsidc.org/egi/request?',
    'short_name={data_id}&',
    'version={data_version}&',
    'format={format}&',
    'time={time}&',
    'page_size=100&',
    'bounding_box={SW},{NE}&',
    'bbox={SW},{NE}',
    '"'
  )

system(
  curl_call
)
