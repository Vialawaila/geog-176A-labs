#Yan Wang
#09/07/2020
#Lab 05

library(tidyverse)
library(sf)
library(raster)
library(getlandsat)
library(mapview)
library(osmdata )

bb = read_csv("data/uscities.csv") %>%
  filter(city  == "Palo") %>%
  st_as_sf(coords = c("lng", "lat"), crs = 4326) %>%
  st_transform(5070) %>%
  st_buffer(5000) %>%
  st_bbox() %>%
  st_as_sfc

mapview(bb)

bwgs = st_transform(bb, 4326)

osm = osmdata::opq(bwgs) %>%
  osmdata::add_osm_feature("building") %>%
  osmdata::osmdata_sf()

mapview(osm$osm_polygons)

bbwgs = st_bbox(bwgs)
scenes = lsat_scenes()

down = scenes %>%
  filter(min_lat <= bbwgs$ymin, max_lat >= bbwgs$ymax,
         min_lon <= bbwgs$xmin, max_lon >= bbwgs$xmax,
         as.Date(acquisitionDate) == as.Date("2016-09-26"))

write.csv(down, file = "data/palo-flood.csv", row.names = F)


meta = read_csv("data/palo-flood.csv")

files = lsat_scene_files(meta$download_url) %>%
  filter(grepl(paste0("B",1:6,".TIF$", collapse = "|"), file)) %>%
  arrange(file) %>%
  pull(file)

st = sapply(files, lsat_image)

s = stack(st) %>%
  setNames(paste0("band", 1:6))

cropper = bb %>%
  st_as_sf() %>%
  st_transform(crs(s))

