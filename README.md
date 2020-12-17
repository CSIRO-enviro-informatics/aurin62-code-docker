# AURIN62 Deployment scripts

This repository contains the deployment scripts for deploying WESC datasets for the 
AURIN6/2 project. The deployment uses docker-geoserver (https://github.com/CSIRO-enviro-informatics/docker-geoserver) to publish services out as a Apache/Geoserver/PostGIS stack with harmonised 
content using the WESCML information model (see http://csiro-enviro-informatics.github.io/wescml).

Attribution Statement: Yu, Jonathan; Leighton, Ben; Mirza, Fareed; Singh, Ramneek (2020): AURIN Lens 6/2 Project Deployment Code. v1. CSIRO. Software Collection. https://doi.org/10.25919/xskv-ej23 


## Pre-requisites

* aurin62 data in /aurin62-data

The rest gets pulled in from Github and docker hub


## Create AURIN62 containers via script

Edit `AurinDataSelections.txt` to add in lines from `AurinDataSelectionsTemplate.txt`. 
This selects which dataset containers to create.

Then run the following script. This iterates through each line in `AurinDataSelections.txt`
and creates the repository binding to respective ports etc. via Docker.

```
$ ./AurinRun.sh
```

Note, Dockerfile configures the deployment and which datasets get used, etl, geoserver, etc.

Once deployed, you'll find the geoserver endpoints at:
https://<server name>:<mapped port>/geoserver

e.g. https://localhost:8180/geoserver/

Note: HTTPS and the default username/password of aurin/aurin (please change these during actual deployment)

You should be able to query via WFS depending on the feature type (wescml-sf0:CombinedMeterReadings, wescml-sf0:WaterSupply or wescml-sf0:ElectricitySupply). This corresponds to the data model published at https://csiro-enviro-informatics.github.io/wescml. An example query is:

https://localhost:8180/geoserver/wescml-sf0/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=wescml-sf0:CombinedMeterReadings&maxFeatures=50


## Manually create each aurin container (deprecated)

Run:
$ docker build --no-cache -t aurin .
$ docker run -p 2223:22 -p 8444:443 aurin 

In a browser try:
 https://localhost:8444/geoserver
