old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

if(interactive()) {
  dotenv::load_dot_env(file = here::here('.env'))
  uid <- Sys.getenv('UID')
  pwd <- Sys.getenv('PWD')
}

instrument <- 'VIIRS'
data_id <- 'VNP10A1F'
data_version <- '1'
format <- 'HDF-EOS5'
time <- '2023-03-10,2023-03-15'

wget_call <- 
  glue::glue(
    'wget ',
    '--http-user={uid} ',
    '--http-password={pwd} ',
    '--load-cookies .urs_cookies ',
    '--save-cookies .urs_cookies ',
    '--keep-session-cookies ',
    '--no-check-certificate ',
    '--auth-no-challenge=on ',
    '-r --reject "index.html*" ',
    '-np -e robots=off ',
    # 'https://n5eil01u.ecs.nsidc.org/',
    # '{instrument}/{data_id}/',
    # '2019.10.07/',
    # 'SMAP_L4_C_mdl_20191007T000000_Vv6042_001.h5'
    'https://n5eil01u.ecs.nsidc.org/SMAP/SPL4CMDL.006/2019.10.07/SMAP_L4_C_mdl_20191007T000000_Vv6042_001.h5'
    # 'https://n5eil02u.ecs.nsidc.org/egi/request?short_name=MOD10A1&version=6&time=2018-05-31T17:03:36,2018-06-01T06:47:53&bounding_box=-24.697,63.281,-13.646,66.717&agent=NO&page_size=100'
  )

curl_call <- 
  glue::glue(
    'curl ',
    '-b ~/.urs_cookies ',
    '-c ~/.urs_cookies ',
    '-L -n -O -J ',
    '--user "{uid}:{pwd}" ',
    '--digest ',
    '--dump-header response-header.txt ',
    '"https://n5eil02u.ecs.nsidc.org/egi/request?',
    'short_name={data_id}&',
    'version={data_version}&',
    'format={format}&',
    'time={time}&',
    'agent=NO"'
  )

system(
  curl_call
)
