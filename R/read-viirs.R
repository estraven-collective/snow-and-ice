# read VIIRS data ---------------------------------------------------------

read_viirs_metadata <- function(
    h5_file,
    h5_metadata = '/HDFEOS INFORMATION/StructMetadata.0',
    xdims = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/XDim',
    ydims = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/YDim'
) {
  # read metadata
  meta <- 
    rhdf5::h5read(
      file = h5_file, 
      name = h5_metadata) 
  
  # parse bounding coordinates from metadata
  meta_lines <- 
    stringi::stri_split_lines(meta)[[1]] |>
    stringr::str_remove_all('\t')
  
  upper_left <-
    meta_lines[stringr::str_detect(meta_lines, 'UpperLeftPointMtrs')] |>
    stringr::str_split('\\(|,|\\)', simplify = T)
  
  left <- upper_left[1,2] |> as.numeric()
  up <- upper_left[1,3] |> as.numeric()
  
  lower_right <-
    meta_lines[stringr::str_detect(meta_lines, 'LowerRightMtrs')] |>
    stringr::str_split('\\(|,|\\)', simplify = T)
  
  right <- lower_right[1,2] |> as.numeric()
  low <- lower_right[1,3] |> as.numeric()
  
  
  WSEN <- c(W = left, S = low, E = right, N = up)
  
  # parse resolution
  x <- 
    rhdf5::h5read(h5_file, name = xdims)
  
  y <- 
    rhdf5::h5read(h5_file, name = ydims)
  
  x_step <- x[2] - x[1]
  y_step <- y[2] - y[1]
  
  # checks
  tol <- 1
  stopifnot(
    dplyr::near(
      x[1],
      WSEN['W'],
      tol = tol),
    dplyr::near(
      x[length(x)],
      x[1]  + x_step * (length(x) - 1),
      tol = tol),
    dplyr::near(
      y[1],
      WSEN['N'],
      tol = tol),
    dplyr::near(
      y[length(y)],
      y[1]  + y_step * (length(y) - 1),
      tol = tol)
  )
  
  
  return(
    list(WSEN = WSEN,
         x = x,
         y = y,
         x_step = x_step,
         y_step = y_step)
  )
}

read_viirs <- function(
    h5_file,
    crs_guess = '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs',
    h5_metadata = '/HDFEOS INFORMATION/StructMetadata.0',
    xdims = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/XDim',
    ydims = '/HDFEOS/GRIDS/NPP_Grid_IMG_2D/YDim'
    ) {
  # read metadata
  meta <- read_viirs_metadata(h5_file = h5_file,
                      h5_metadata = h5_metadata)
  
  # read data
  st <- stars::read_stars(h5_file)
  
  # add metadata to star
  attr(st, 'dimensions')$x$offset <- meta$x[1]
  attr(st, 'dimensions')$y$offset <- meta$y[1]
  attr(st, 'dimensions')$x$delta <- meta$x_step
  attr(st, 'dimensions')$y$delta <- meta$y_step
  sf::st_crs(st) <- crs_guess
  
  return(st)
}
