# SMS API 
![workflow](https://github.com/frogr/sms-api/actions/workflows/rubyonrails.yml/badge.svg)

SMS API designed to send messages to a mock service provider. 

## Getting Started
* Clone this repository or a fork of it to your local machine
* Run `bundle install` 
* Run `ngrok http 3000`
* Update `.env` with your `NGROK_CALLBACK_PATH` to expose the API to the internet
* Start your rails server with `rails s` and view the app at `http://localhost:3000`

### Running tests and rubocop
A standard set of unit tests have been included for the controller, model, and message sender service. These can all be ran with `rspec` or `bundle exec rspec`. Rubocop is included as well, and can be ran with the `rubocop` command. These are also ran by default as part of GitHub Actions. 

### GitHub Actions
Upon each commit to the `main` branch, GitHub Actions is set up to automatically run rubocop, rspec, bundler-audit, and brakeman.

## Technical Details
The functional requirements for this project were as follows: 
* Build a public endpoint that accepts requests containing a phone number and a text message body
* When this endpoint receives a request, send an API request to a SMS provider
* Build an endpoint to accept a callback from the SMS provider that updates the message's status
* If a phone number is "invalid", no longer send messages to that phone number

Once a message is created through the new message form, a job is enqueued to send it through the Message Sender Service. The Message Sender Service (MSS) uses load balancing, with 70% of traffic being routed through the first SMS provider, and 30% being directed to the second. MSS will also handle retries, alternating providers on each attempt. 

If a message is ever indicated as "invalid", it is stored in Redis. Upon creation of a new message, we check that Redis store to make sure the number we're sending to isn't in the list of invalid numbers. Since this is a simple lookup operation, Redis can handle it very quickly. If we wanted to display that list of invalid numbers within the app, or otherwise use that store of numbers, it may be end up being more efficient to store these numbers in an indexed DB column instead of Redis. 

## Diagrams
Below is a diagram describing the flow of the code itself, and then a more zoomed out diagram outlining the basic flow of the relevant requests and responses

<details><summary>Code Logic Flow</summary>
<img width="615" alt="Logic Flow (1)" src="https://github.com/frogr/sms-api/assets/24354711/17957318-e7f5-4268-9138-dd52f0747f44">
</details>

<details><summary>Basic API Flow</summary>
  <img width="1024" alt="Base API flow" src="https://github.com/frogr/sms-api/assets/24354711/fc2f75bb-631c-4185-b527-9cfca8109466">
</details>

## Automatic retries
If a message fails, it will automatically retry with another provider. Below are some screenshots of my terminal, generally detailing the process for automatic retries

<details><summary>Automatic failover upon error</summary>
<img width="1024" src="https://github.com/frogr/sms-api/assets/24354711/ed3ff200-33bb-4d15-851a-9b459f80eb0e">
</details>

<details><summary>Retry after initial failure from SMS Provider API</summary>
<img width="1024" src="https://github.com/frogr/sms-api/assets/24354711/59faddaa-1150-477f-8a5b-62538debdebd">
</details>

<details><summary>Retry after error from SMS Provider callback</summary>
<img width="1024" src="https://github.com/frogr/sms-api/assets/24354711/5cc9551f-1f11-426d-a053-aa9099e6e9f8">
</details>



