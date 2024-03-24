# README

# Design Notes

### Limiting calls to Openrouteservice

I took advantage of the ability to fetch matrix data from the Openrouteservice API for all-locations-to-all-locations data. This required careful processing of the matrix data, but that extra complexity bought a significant decrease in API calls and network IO. There is only one Openrouteservice API call per request on the `GET /rides` endpoint, and only if there is a cache miss.

Also, since the Rails Assessment doc stated the driver and rides have addresses, not coords which are required for fetching matrix data, my implementation accepts a street address on creation via API (`POST /drivers` and `POST /rides`). When these records have been created, the coordinates are fetched from Openrouteservice, so there is an additional call per Driver creation, and 2 per Ride creation. 

Since the Driver and Ride creation controllers are fully synchronous and include calls to Openrouteservice, the response is slow.  I didn't optimize for performance here, but the Openrouteservice calls could be done asynchronously.

### Including the driver_id

For the Ride API, I decided to include the driver_id as a GET parameter for a number of reasons, although it's not a perfect solution. The Rides are not associated to a Driver, so nesting drivers/:driver_id/rides doesn't seem appropriate, and this would likely be used for rides that the driver has agreed to drive (outside the scope of this project).  Ideally, the driver would be logged in and we could use :current_user or similar, but since auth was also out of scope, I went with the GET param as a compromise between the two. 

### Pagination and caching

Pagination has two paths: cache hits and cache misses

For cache misses, all Rides are scored and sorted by score in descending order, and then the correct number of records are selected at the correct offset. They are returned along with other pagination fields.  This is fairly traditional pagination except that we can't query the database for the offset of records since they aren't scored yet.  After we know the Ride scores for a driver, the Ride ids are saved to the cache in sorted order (by score, descending) to a key containing the driver_id.

For cache hits, the driver has recently (in the last 5 minutes) fetched a page of scored Ride records with the cache miss path.  This time, the API will fetch an array of Ride ids in Redis by the driver's cache key. The array be used to find the requested page of records with minimal time, space, and network complexity.  For page=1 and per_page=5, we grab the first 5 Ride ids from the array and query for them in the database, sort them efficiently in order of the cached ids, and return them in the response.

#### Important

I chose a 5 minute cache so the driver could generally experience quick page loads without waiting too long to see new records in an API response.  If you use the API to create a new Ride record, remember this caching mechanism! Either use a new driver to get fresh data or wait until the cache expires.

### Testing

The pattern I have used here is to treat the controller specs as behavioral tests.  They only stub external network calls, so this gives happy-path and expected errors test coverage for the whole system accessible to by the API. 

Then, I wrote unit tests for models and services where they were not robustly tested by the controller tests.

#### Future improvements

In a real scenario, I would also want an integration test for Openrouteservice to run in the different environments to ensure that system is healthy and we are accessing their API correctly.

Performance tests would also be useful in a real scenario so I could test future optimizations, see how much faster the caching approach is than non-cached, and see improvements made with async behavior.

# Ride API

This API provides endpoints to manage rides.

## Endpoints

### GET /rides

Retrieves rides for a specific driver, ordered based on the ride's score for this driver.

#### Parameters

- `driver_id`: REQUIRED. The ID of the driver to retrieve and score rides for.

#### Pagination

Pagination is implemented using query parameters `page` and `per_page`.  The response is cached for 5 minutes, so if newly created Ride records don't appear in the response, try again later.

- `page`: The page offset, defaults to 1.
- `per_page`: The number of results per page, defaults to 10.

#### Response

- `200 OK`: Returns paginated rides for the specified driver.
- `400 Bad Request`: Returned if `driver_id` parameter is missing or if the driver does not have set coords. For the second case, create a different driver and ensure the home_address is valid.
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


# Local Deployment

This API can be deployed to any platform that supports Ruby on Rails applications. To run the API locally:

### 1. Install dependencies:

- Use rvm or similar tool to ensure your terminal is running ruby-3.3.0

- `bundle install` 

- `rails db:create`

- `rails db:migrate`

- `brew install redis`  (This works for MacOS.  If you are using another OS, lookup the correct way to install redis on your system if it is not installed.)

- `gem install foreman`

- copy `.sample_env` to a file called `.env` and replace `your-api-key` with a real api key from Openrouteservice

### 2. Run specs:

- `rspec`

### 3. Run the server:

- `foreman start`

### 4. The API will be accessible at `http://localhost:3000`

## Known issues:
    If an error is encountered for Redis similar to:
    "ERROR: heartbeat: MISCONF Redis is configured to save RDB snapshots, but 
    it's currently unable to persist to disk. Commands that may modify the data 
    set are disabled, because this instance is configured to report errors 
    during writes if RDB snapshotting fails (stop-writes-on-bgsave-error 
    option). Please check the Redis logs for details about the RDB error."

Try

- `brew services restart redis`
