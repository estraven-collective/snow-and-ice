old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

# if(interactive()) {
#   dotenv::load_dot_env(file = here::here('.env'))
#   uid <- Sys.getenv('UID')
#   pwd <- Sys.getenv('PWD')
# }

instrument <- 'VIIRS'
data_id <- 'VNP10A1F'
data_version <- '1'
format <- 'HDF-EOS5'
time <- '2023-03-10T00:00:00,2023-03-15T12:00:00'

curl_call <- 
  glue::glue(
    'curl ',
    '-b .urs_cookies ',
    '-c .urs_cookies ',
    '-L -O ',
    '--netrc-file .netrc ',
    '-J ',
    # '--user "{uid}:{pwd}" ',
    # '--digest ',
    '--dump-header response-header.txt ',
    '"https://n5eil02u.ecs.nsidc.org/egi/request?',
    'short_name={data_id}&',
    'version={data_version}&',
    'format={format}&',
    'time={time}&',
    'page_size=100&',
    'agent=NO"'
    # '"https://n5eil02u.ecs.nsidc.org/egi/request?short_name=SPL3SMP&version=007&format=GeoTIFF&time=2018-06-06,2018-06-07&bounding_box=-109,37,-102,41&bbox=-109,37,-102,41&Coverage=/Soil_Moisture_Retrieval_Data_AM/soil_moisture&projection=Geographic&page_size=100"'
  )

system(
  curl_call
)
