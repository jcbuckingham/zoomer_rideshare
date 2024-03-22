# README

* Ruby version

Use rvm or similar tool to ensure your terminal is running ruby-3.3.0

* System dependencies

- bundle install

* Configuration

* Database creation

- rails db:create
- brew install redis  (This works for MacOS.  If you are using another OS, lookup the correct way to install redis on your system if it is not installed.)
- brew services start redis
- brew services info redis (To verify redis is installed and up)

* Database initialization

- rails db:migrate
- redis-server

* How to run the test suite

- rspec

* Services (job queues, cache servers, search engines, etc.)

- bundle exec sidekiq

* Deployment instructions

* Troubleshooting

If an error is encountered for Redis similar to:
"ERROR: heartbeat: MISCONF Redis is configured to save RDB snapshots, but it's currently unable to persist to disk. Commands that may modify the data set are disabled, because this instance is configured to report errors during writes if RDB snapshotting fails (stop-writes-on-bgsave-error option). Please check the Redis logs for details about the RDB error."

Try: 
- brew services restart redis

curl -v \
  -H "Accept: application/json" \
  -H "Content-type: application/json" \
  -X POST \
  -d '{"ride":{"destination_address":"8.682301,49.420658","start_address":"8.643600,49.41401"}}' \
  http://localhost:3000/rides

curl -v \
  -H "Accept: application/json" \
  -H "Content-type: application/json" \
  -X POST \
  -d '{"driver":{"home_address":"8.685072,49.421518"}}' \
  http://localhost:3000/drivers

  curl -X POST -H "Content-Type: application/json" -H 'Authorization: 5b3ce3597851110001cf6248f34895a0bde54f7a981a91c84076381e' -d '{"locations":[[8.681495,49.41461],[8.6816,49.41401],[8.682301,49.414658],[8.68171,49.41401],[8.692301,49.414658],[8.6825,49.41401],[8.682311,49.414658],[8.6815,49.41464],[8.6814,49.41461]],"metrics":["duration", "distance"],"resolve_locations":"false","units":"mi"}' https://api.openrouteservice.org/v2/matrix/driving-car

curl -X POST \
  'https://api.openrouteservice.org/v2/matrix/driving-car' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Authorization: 5b3ce3597851110001cf6248f34895a0bde54f7a981a91c84076381e' \
  -d '{"locations":[[8.685072,49.421518],[8.6436,49.41401],[8.682301,49.420658],[8.6936,49.41401],[8.692301,49.420658]],"metrics":["duration","distance"],"resolve_locations":"false","units":"mi"}' 