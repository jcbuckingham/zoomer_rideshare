# README

## Local Deployment

This API can be deployed to any platform that supports Ruby on Rails applications. To run the API locally:

### 1. Install dependencies:

- Navigate to the project root before doing any of the install steps

- Use rvm or similar tool to ensure your terminal is running ruby-3.3.0

- `bundle install` 

- `rails db:create`

- `rails db:migrate`

- copy `.sample_env` to a file called `.env` and replace `your-api-key` with a real api key from Openrouteservice

#### Install these dependencies if they are not already installed on your computer

- `brew install redis`  (This works for MacOS.  If you are using another OS, lookup the correct way to install Redis on your system.)

- `gem install foreman`

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


# API Documentation


## Ride API

This API provides endpoints to manage Rides.

### Endpoints

#### GET /rides

Retrieves Rides for a specific Driver, ordered based on the ride's score for this Driver.

##### Parameters

- `driver_id`: REQUIRED. The ID of the driver to retrieve and score rides for.

##### Pagination

Pagination is implemented using query parameters `page` and `per_page`.  The response is cached for 5 minutes, so if newly created Ride records don't appear in the response, try again later.

- `page`: The page offset, defaults to 1.
- `per_page`: The number of results per page, defaults to 10.

##### Response

- `200 OK`: Returns paginated rides for the specified driver.
- `400 Bad Request`: Returned if `driver_id` parameter is missing or if the Driver does not have set coords. For the second case, create a different Driver and ensure the home_address is valid.
- `404 Not Found`: Returned if the Driver with the specified ID is not found.
- `503 Service Unavailable`: Returned if there is an issue fetching Ride information.
- `500 Internal Server Error`: Returned if an unexpected error occurs.

#### GET /rides/:id

Retrieves details of a specific Ride.

##### Parameters

- `id`: The ID of the ride to retrieve.

##### Response

- `200 OK`: Returns details of the specified Ride.
- `404 Not Found`: Returned if the Ride with the specified ID is not found.

#### POST /rides

Creates a new ride.  This endpoint is slow due to synchronously creating the record and fetching coordinates from Openrouteservice.  Be patient when waiting for a response.

##### Parameters

- `start_address`: REQUIRED. The starting address of the Ride.
- `destination_address`: REQUIRED. The destination address of the Ride.

##### Response

- `201 Created`: Returns the details of the newly created Ride.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

#### DELETE /rides/:id

Deletes a specific Ride.

##### Parameters

- `id`: The ID of the Ride to delete.

##### Response

- `204 No Content`: Returned if the Ride is successfully deleted.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

## Driver API

This API provides endpoints to manage Drivers.

### Endpoints

#### GET /drivers/:id

Retrieves details of a specific Driver.

##### Parameters

- `id`: The ID of the Driver to retrieve.

##### Response

- `200 OK`: Returns details of the specified Driver.
- `404 Not Found`: Returned if the Driver with the specified ID is not found.

#### POST /drivers

Creates a new Driver. This endpoint is slow due to synchronously creating the record and fetching coordinates from Openrouteservice.  Be patient when waiting for a response.

##### Parameters

- `home_address`: REQUIRED. The home address of the Driver.

##### Response

- `201 Created`: Returns the details of the newly created Driver.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

#### DELETE /drivers/:id

Deletes a specific Driver.

##### Parameters

- `id`: The ID of the Driver to delete.

##### Response

- `204 No Content`: Returned if the Driver is successfully deleted.
- `400 Bad Request`: Returned if there is an issue with the request parameters.

### Error Handling

- Errors are returned with appropriate HTTP status codes and error messages in JSON format.

### Authentication, Authorization, Rate Limiting

Not implemented in this API.
