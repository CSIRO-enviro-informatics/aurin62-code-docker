# AURIN62 Deployment scripts

Pre-requisite:
* csiro_env/geoserver - clone and build from  https://github.com/CSIRO-enviro-informatics/docker-geoserver/
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



## Manually create each aurin container (deprecated)

Run:
$ docker build --no-cache -t aurin .
$ docker run -p 2223:22 -p 8444:443 aurin 

In a browser try:
 https://localhost:8444/geoserver
