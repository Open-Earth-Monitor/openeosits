# Install package from GitHub
if(!require(openeosits)){
  remotes::install_github("Open-Earth-Monitor/openeosits", ref = "develop", dependencies=TRUE, force = TRUE)
}
# Start service
library(openeosits)

aws.host <-Sys.getenv("AWSHOST")

if (aws.host == ""){
  aws.host = NULL
}else{
  message("AWS host port id is:")
  message(aws.host)
}


config = SessionConfig(api.port = 8000, host = "0.0.0.0", aws.ipv4 = aws.host)
config$workspace.path = "/var/openeo/workspace"
createSessionInstance(config)
Session$startSession()
