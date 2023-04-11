
# add functions installed with brew to path -------------------------------

old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

# parameters --------------------------------------------------------------

fetch_viirs <- function(
    instrument = 'VIIRS',
    data_id = 'VNP10A1F',
    data_version = '1',
    format = 'HDF-EOS5',
    start_date = '2012-01-01', # YYYY-MM-DD
    end_date = '2012-12-31', # YYYY-MM-DD
    page_size = 1000,
    W = 5,
    S = 43,
    E = 13,
    N = 48,
    output_folder = 'query_output',
    request_file = 'request.xml',
    response_file = 'response.xml',
    cookie_path = here::here(output_folder, '.urs_cookies'),
    auth_path = here::here('.netrc'),
    output_zip = here::here(output_folder, 'output.zip'),
    data_folder = 'data',
    output_unzipped = here::here(data_folder, 'query-test'),
    wait = 30, # seconds between each call to check if data are ready
    n_try = 300 # check if data are ready for download n times before giving up 
) {
  time <-  glue::glue('{start_date}T00:00:00,{end_date}T12:00:00')
  
  WSEN <- glue::glue('{W},{S},{E},{N}')
  
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
      'page_size={page_size}&',
      'bounding_box={WSEN}&',
      'bbox={WSEN}&',
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
      cat('Done\n')
      break
    }
    else if(response_status == 'processing' | response_status == 'pending') {
      cat(glue::glue('Tentative: {i}. Request status is: "{response_status}".'), '\n')
      cat(glue::glue('Trying again in {wait} seconds...'), '\n')
      Sys.sleep(wait)
    } else {
      stop('unknown response status: ', response_status)
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
  
  # return path to zipped folder --------------------------------------------
  
  return(output_zip)
}
