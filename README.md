
# openeosits: OpenEO Compliant R Backend Platform for Processing Time Series Satellite Images

The service wraps SITS R package to be a lightweight platform to enable analysis of time series satellite images via OpenEO Compliant RESTful endpoints. 

####  The Concept:
![](docs/openeosits.png)


## Easy Deployment with Docker
If you want to change the source code then this approach is recommended.
You first need to clone the repository via this command:

```bash
git clone https://github.com/Open-Earth-Monitor/openeosits.git
```

then you can change to that directory

```bash
cd openeosits
```

Run it :

```bash
docker-compose up
```

Run in detached mode :

```bash
docker-compose up -d
```

Shutting it down:

```bash
docker-compose down
```

Force restart  and rebuild:

```bash
docker-compose up --build --force-recreate --no-deps -d
```

If there are new changes on the images or Dockerfiles:
```bash
docker-compose build --no-cache && docker-compose up
```

## Development Notes:
While developing, you can skip rebuilding the docker container everytime. Instead you can run the server locally. Just run "Rscript startLocal.R" inside this directory.

This will compile this Repository as a R Package and start the server.

```bash
Rscript startLocal.R
```