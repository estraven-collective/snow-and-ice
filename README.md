# Reproduce the analysis

## 1. Register to Earthdata, Store your Credentials

In order to download satellite data from NASA Earthdata portal, you will have to [register on their website](https://www.earthdata.nasa.gov/eosdis/science-system-description/eosdis-components/earthdata-login) and get a **user id** and a **password**.

Store your user id and your password in a `.netrc` file, located in the root of this repo.

```sh
echo 'machine urs.earthdata.nasa.gov login <uid> password <password>' >> .netrc
chmod 0600 .netrc
```

## 2. Restore the R environment

All R packages in this project are versioned with [renv](https://rstudio.github.io/renv/articles/renv.html).

1.  Open the project [bologna-data.Rproj](bologna-data.Rproj) in RStudio.
2.  At the R console, run:

``` r
renv::restore()
```
