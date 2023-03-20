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
output_folder <- 'query_output'
request_file <- 'request.xml'
response_file <- 'response.xml'
cookie_path <- here::here(output_folder, '.urs_cookies')
auth_path <- here::here('.netrc')
output_zip <- here::here(output_folder, 'output.zip')

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
    'bounding_box={SW},{NE}&',
    'bbox={SW},{NE}',
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

system(
  id_poll
)

# parse the response status ------------------------------------------------

response_status <- system(
  glue::glue(
    "grep status {{output_folder}}/{{response_file}} | awk -F '<|>' '{print $3}'",
    .open = '{{', .close = '}}'
  ),
  intern = T
)

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
