# README

# Ride API

This API provides endpoints to manage rides.

## Endpoints

### GET /rides

Retrieves rides for a specific driver.

#### Parameters

- `driver_id`: REQUIRED. The ID of the driver for whom to retrieve rides.

#### Pagination

Pagination is implemented using query parameters `page` and `per_page`.

- `page`: The page offset, defaults to 1.
- `per_page`: The number of results per page, defaults to 10.

#### Response

- `200 OK`: Returns paginated rides for the specified driver.
- `400 Bad Request`: Returned if `driver_id` parameter is missing.
- `404 Not Found`: Returned if the driver with the specified ID is not found.
- `503 Service Unavailable`: Returned if there is an issue fetching ride information.
- `500 Internal Server Error`: Returned if an unexpected error occurs.

### GET /rides/:id

Retrieves details of a specific ride.

#### Parameters

- `id`: The ID of the ride to retrieve.

#### Response

- `200 OK`: Returns details of the specified ride.
- `404 Not Found`: Returned if the ride with the specified ID is not found.

### POST /rides

Creates a new ride.

#### Parameters

- `start_address`: The starting address of the ride.
- `destination_address`: The destination address of the ride.

#### Response

- `201 Created`: Returns the details of the newly created ride.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

### DELETE /rides/:id

Deletes a specific ride.

#### Parameters

- `id`: The ID of the ride to delete.

#### Response

- `204 No Content`: Returned if the ride is successfully deleted.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

# Driver API

This API provides endpoints to manage drivers.

## Endpoints

### GET /drivers/:id

Retrieves details of a specific driver.

#### Parameters

- `id`: The ID of the driver to retrieve.

#### Response

- `200 OK`: Returns details of the specified driver.
- `404 Not Found`: Returned if the driver with the specified ID is not found.

### POST /drivers

Creates a new driver.

#### Parameters

- `home_address`: The home address of the driver.

#### Response

- `201 Created`: Returns the details of the newly created driver.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

### DELETE /drivers/:id

Deletes a specific driver.

#### Parameters

- `id`: The ID of the driver to delete.

#### Response

- `204 No Content`: Returned if the driver is successfully deleted.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

## Error Handling

- Errors are returned with appropriate HTTP status codes and error messages in JSON format.

## Authentication, Authorization, Rate Limiting

Not implemented in this API.

## Deployment

This API can be deployed to any platform that supports Ruby on Rails applications.

## Development

To run the API locally:

1. Install dependencies:

- Use rvm or similar tool to ensure your terminal is running ruby-3.3.0

- `bundle install`

- `rails db:create`

- `rails db:migrate`

- `brew install redis`  (This works for MacOS.  If you are using another OS, lookup the correct way to install redis on your system if it is not installed.)

- `gem install sidekiq`

- copy `.sample_env` to a file called `.env` and replace `your-api-key` with a real key from Openrouteservice

2. Run specs:

- `rspec`

3. Run the server:

- `brew services start redis` OR `docker-compose up`

- `bundle exec sidekiq`

- `bin/rails server`

4. The API will be accessible at `http://localhost:3000`




## Notes:
### Known issues:
    Cache is not expiring as expected, but it seemed like a fiddly issue to 
    spend time on here.  If this was a real feature going to production I would 
    ensure that the cache is expiring correctly, but I hope you will accept that 
    since I have limited free time in my week and this is just a demonstration 
    of skill and not a real product, that my time is better served by calling 
    this issue a "I would fix if I had more time".

    If an error is encountered for Redis similar to:
    "ERROR: heartbeat: MISCONF Redis is configured to save RDB snapshots, but 
    it's currently unable to persist to disk. Commands that may modify the data 
    set are disabled, because this instance is configured to report errors 
    during writes if RDB snapshotting fails (stop-writes-on-bgsave-error 
    option). Please check the Redis logs for details about the RDB error."

Try: 
- `brew services restart redis`
