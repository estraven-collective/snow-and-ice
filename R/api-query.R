
# add functions installed with brew to path -------------------------------

old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

# parameters --------------------------------------------------------------


instrument <- 'VIIRS'
data_id <- 'VNP10A1F'
data_version <- '1'
format <- 'HDF-EOS5'
time <- '2023-03-10T00:00:00,2023-03-15T12:00:00'
W <- 6
S <- 43
E <- 14
N <- 48
WSEN <- glue::glue('{W},{S},{E},{N}')
output_folder <- 'query_output'
request_file <- 'request.xml'
response_file <- 'response.xml'
cookie_path <- here::here(output_folder, '.urs_cookies')
auth_path <- here::here('.netrc')
output_zip <- here::here(output_folder, 'output.zip')
data_folder <- 'data'
output_unzipped <- here::here(data_folder, 'query-output')

# make a request to earthdata ---------------------------------------------

curl_call <- 
  glue::glue(
    'curl ',
    '-b {cookie_path} ',
    '-c {cookie_path} ',
    '-L ',
    '-o "{output_folder}/{request_file}" ',
    '--netrc-file {auth_path} ',
    '-J ',
    '--dump-header {output_folder}/response-header.txt ',
    '"',
    'https://n5eil02u.ecs.nsidc.org/egi/request?',
    'request_mode=async&',
    'short_name={data_id}&',
    'version={data_version}&',
    'format={format}&',
    'time={time}&',
    'page_size=100&',
    'bounding_box={WSEN}&',
    'bbox={WSEN}',
    '"'
  )

system(
  curl_call
)


# parse the request ID ----------------------------------------------------

query_id <- system(
  glue::glue(
    "grep orderId {{output_folder}}/{{request_file}} | awk -F '<|>' '{print $3}'",
    .open = '{{', .close = '}}'
  ),
  intern = T
)


# poll for status ---------------------------------------------------------

id_poll <- 
  glue::glue(
    'curl ',
    '-s ',
    '-b {cookie_path} ',
    '-c {cookie_path} ',
    '-L ',
    '--netrc-file {auth_path} ',
    '-o "{output_folder}/{response_file}" ',
    'https://n5eil02u.ecs.nsidc.org/egi/request/{query_id}'
  )

n_try <- 300

for(i in 1:n_try) {
  system(
    id_poll
  )
  
  response_status <- system(
    glue::glue(
      "grep status {{output_folder}}/{{response_file}} | awk -F '<|>' '{print $3}'",
      .open = '{{', .close = '}}'
    ),
    intern = T
  )
  
  if(response_status == 'complete') {
    break
  }
  else if(response_status == 'processing') {
    Sys.sleep(10)
  } else {
    stop('response status is: ', response_status)
  }
}

# download zipped output --------------------------------------------------

download_out <- 
  glue::glue(
    'curl ',
    '-s ',
    '-b {cookie_path} ',
    '-c {cookie_path} ',
    '-L ',
    '--netrc-file {auth_path} ',
    '-o "{output_zip}" ',
    'https://n5eil02u.ecs.nsidc.org/esir/{query_id}.zip'
  )

system(
  download_out
)


# unzip into data folder --------------------------------------------------

unzip(zipfile = output_zip,
      exdir = output_unzipped)
