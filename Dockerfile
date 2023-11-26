# Use a stable Ubuntu version
FROM rocker/rstudio:4.3

# Install essential tools
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    software-properties-common \
    cmake \
    g++ \
    git \
    supervisor \
    wget

# Install dependencies
RUN apt-get install -y \
    libnetcdf-dev \
    libcurl4-openssl-dev \
    libcpprest-dev \
    doxygen \
    graphviz \
    libsqlite3-dev \
    libboost-all-dev

# Install devtools in R
RUN Rscript -e "install.packages(c('devtools'))"

# Install additional R packages
RUN apt-get install -y libsodium-dev libudunits2-dev
RUN Rscript -e "install.packages(c('plumber', 'useful', 'ids', 'R6', 'sf', 'rstac','bfast', 'stars', 'geojsonsf'))"
RUN Rscript -e "install.packages('sits')"
RUN Rscript -e "install.packages('gdalcubes')"

# Create directories
RUN mkdir -p /opt/dockerfiles/ \
    && mkdir -p /var/openeo/workspace/ \
    && mkdir -p /var/openeo/workspace/data/

# Install local packages
COPY ./ /opt/dockerfiles/
RUN Rscript -e "remotes::install_local('/opt/dockerfiles', dependencies=TRUE)"

# Set the startup command
CMD ["R", "-q", "--no-save", "-f /opt/dockerfiles/Dockerfiles/start.R"]

# Expose port
EXPOSE 8000