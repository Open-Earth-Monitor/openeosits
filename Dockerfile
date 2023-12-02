FROM r-base:4.3.0

# Install software dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common cmake g++ git supervisor wget
ENV TZ=Etc/UTC
RUN apt-get install  -y libnetcdf-dev libcurl4-openssl-dev libcpprest-dev doxygen graphviz  libsqlite3-dev libboost-all-dev
RUN apt-get update && apt-get install -y libproj-dev libgdal-dev

RUN apt-get install -y libfreetype-dev

# Install devtools package
RUN R -e "install.packages('devtools')"

# Install gdalcubes package
RUN R -e "install.packages('gdalcubes')"

# Install sits package
RUN R -e "install.packages('sits')"

# Install other necessary packages
RUN apt-get install -y libsodium-dev libudunits2-dev
RUN R -e "install.packages(c('plumber', 'useful', 'ids', 'R6', 'sf', 'stars','rstac','bfast', 'geojsonsf', 'torch'))"

# Create directories
RUN mkdir -p /opt/dockerfiles/ && mkdir -p /var/openeo/workspace/ && mkdir -p /var/openeo/workspace/data/

# Install packages from the local directory
COPY ./ /opt/dockerfiles/
RUN R -e "remotes::install_local('/opt/dockerfiles', dependencies = TRUE)"

# CMD or entrypoint for startup
CMD ["R", "-q", "--no-save", "-f", "/opt/dockerfiles/Dockerfiles/start.R"]

# Expose the port
EXPOSE 8000