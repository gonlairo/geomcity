# shape-cities

## code documentation

src:
- preprocessing/
- optimal_threshold/
- polygons/
- instrument/
- tracking/

![alt text](https://github.com/gonlairo/tfg/blob/master/src/citypoints%20_noNAF.png)
STEPS:

1. PREPROCESSING:

NTL images -> intercalibration -> intra-anual composition -> inter-anual series correction

1.1 preprocessing/intra_annual_composition.R: average between different satellites of the same year (Ex: F101994 and F121994) (input: zhang et al images, output: annual_composites)

1.2 preprocessing/temporal_adjustment.R: implements two approaches (Liu 2012 and Liu 2015) to temporally adjust the satellite images. (input: annual_composites + others (comp+others), outupt: oneway and twoway (backward and forward))

At the end I get final/ which are the average images between backward and forward.

2. OPTIMAL THRESHOLDS

I tried to use the histogram analysis that I saw in the world bank paper but it didnt work that well so I went country by country and I manually assess which threshold made more sense. Therefore src/optimal_threshold is a mess.

Result: data/thresholds/final_thresholds.csv. In this directory there are lower bound (25% less) and upper bounds (25 % more).

3. URBAN POLYGONS

Given the "optimal" threshold, I create the urban polygons for each of the years availabe of NTL satellite images (ups_computation.R), which uses the function urban_polygon.R. I create a folder for each country and inside that folder one file per NTL image available. In other words,  81(countries)\*21(years) = 1701 files. They are located in data/ups/asia_africa/

4. TRACKING (potentially improvable): I tried multiple ways to track: UCDB:
- tracking1
- tracking2
- tracking3

Result: data/final/finalups3395.gpkg, finalups4326.gpkg, finalups_noNAF_3395.gpkg (no north africa)

5. INSTRUMENT

- developable land (africa_asia15.tif)

First I download the ASTER GDEM v.3. This is a global digital elevation model of the whole world. After that, I download the  ASTER Water body dataset. When you download these products, you download tiles / granules. For example for Asia and Africa there are more than 6500 granules. Once you have those we need to join them together to create only one file.

To dowload the granules we use the bash script (curl) that EarthData NASA provides: src/instrument/download_ASTER/gdem-download-all.sh
To merge them we use: gdem_merge.R and water_merge.R

After that we need to compute a slope map. One important thing is that the projection you use to calculate the slope map has to have the same units in each axis. When you download ASTER datasets they are in EPSG:4326. I had to convert the tif to the mercator projection. Once I had ASTER GDEM in mercator i used gdal_dem to do it. Finally, I created the developable land as land that is less than 15% and has not water bodies.

- radius (all_radius.shp)

There are two ways of calulating the "projected" radius we need to calculate later the potential footprints.

    - First way: compute the population growth rate from the past (in my case I computed the growth rate between 1975 and 1990 using the UCDB database (European JRC) and then project the population between 1992 an 2012 (my data). Then I run this regression:

        ln(area c,t) = alpha * log(pop_proj c,t) + beta * density1990 + fixed effects time + error c,t
        radius = sqrt(predicted / pi)

    - Second way: Run the regression:
        log(area c,t) = fiexed effects city + fixed effects time + error c,t
        radius2 = sqrt(predicted / pi)


- potential footprint: (potential footprint.shp)

First we need to compute the the concentric circles (model of city expansion) with the radius calculate in the step before. Once we have those we need to crop & mask them with developable land to create the "potential footprint". The result would be a shapefile where the geometry column are polygons which represent the potential footprint throughout time for each city.

6. SHAPEMETRICS (independent variable and instrument)

We decided to only work with single part polygons. To compute shapemetrics I am using the code from ShapeMetrics people (look them up -- email). I am using their code from python without using arcgis.

shapemetrics.pyx is the main code (cython -- interpointDistance only --)

Shapemetrics:
    - cohesion index
    - ...

Functions:
- convertogridpoitns()
- interpointDistance()
- ....

** interpointDistance() was too slow so I used Cython to make it faster. I get around 10x improvement.
Steps:
- setup.py
- intrerpointDistance.pyx

7. MODELS

models/graphs.R
models/iv.R
models/ivqr.R

I used plm package to deal with panel data.

** There are many subtleties and I acknowledge the code is not fully reproducible but I hope it will be in the future. Questions about the code are welcome **
