old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(old_path, "/opt/homebrew/bin:/opt/homebrew/sbin", sep = ":"))

if(interactive()) {
  dotenv::load_dot_env(file = here::here('.env'))
  uid <- Sys.getenv('UID')
  pwd <- Sys.getenv('PWD')
}

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
    'https://n5eil01u.ecs.nsidc.org/SMAP/SPL4CMDL.006/2019.10.07/SMAP_L4_C_mdl_20191007T000000_Vv6042_001.h5'
  )

system(
  wget_call
)
