FROM r-base:4.3.1

# Set the timezone
ENV TZ=Etc/UTC

# Install software dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common \
    cmake \
    g++ \
    git \
    supervisor \
    wget \
    libnetcdf-dev \
    libcurl4-openssl-dev \
    libcpprest-dev \
    doxygen \
    graphviz \
    libsqlite3-dev \
    libboost-all-dev \
    libproj-dev \
    libgdal-dev

# Install devtools and remotes
RUN R -e "install.packages(c('devtools', 'remotes'))"

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
