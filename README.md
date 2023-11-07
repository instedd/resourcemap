# Resource Map

[Resource Map](http://instedd.org/technologies/resource-map/) helps people track
their work, resources and results geographically in a collaborative environment
accessible from anywhere.

Resource Map is a free, open-source tool that helps you make better decisions by
giving you better insight into the location and distribution of your resources.
With Resource Map, you and your team can collaboratively record, track, and
analyze resources at a glance using a live map. Resource Map works with any
computer or cell phone with text messaging capability, putting up-to-the-minute
alerts and powerful resource management always within reach, wherever you go.

Please refer to [the wiki](https://github.com/instedd/resourcemap/wiki) for more
information.


## Development Setup

### Dependencies

Resource Map is a standard Rails application, but also needs the following
services to run:

* [Elasticsearch](http://elastic.co/products/elasticsearch) 1.7
* [Redis](http://redis.io)
* [MySQL](http://www.mysql.com)

### Installation on Mac OS X

Use [Homebrew](http://brew.sh) to retrieve and install the required
dependencies.

Install the 1.7 series of elasticsearch (Homebrew defaults to the latest version
which may introduce compatibility problems):

    brew install homebrew/versions/elasticsearch17

Then install Redis with:

    brew install redis

Likewise, MySQL server installation is straightforward:

    brew install mysql

### Installation on Ubuntu Linux

Install Elasticsearch from the official download site using .deb packages by
following the instructions given at https://www.elastic.co/guide/en/elasticsearch/reference/1.7/setup-repositories.html

For Redis server, you can use the version provided in the distribution:

    sudo apt-get install redis-server

Likewise for MySQL:

    sudo apt-get install mysql-server


### Rails Setup

The current required Ruby version is 2.1.2. We recommend you use a Ruby version
manager to handle parallel installations of different Ruby versions.
[rbenv](https://github.com/rbenv/rbenv) and [RVM](http://rvm.io) are both
supported.

1. Install the bundle:

    ```
    bundle install
    ```

2. Create and setup de database

   ```
   bundle exec rake db:setup
   ```

## Running in development

Once the application has been setup, run the application in development mode:

    bundle exec rails server

To run the background jobs (through [resque](https://github.com/resque/resque))
execute:

    bundle exec rake resque:work

### Running the tests

Resource Map has unit tests, acceptance tests (using
[Capybara](https://github.com/jnicklas/capybara)) and Javascript tests.

Execute the unit tests through [Rspec](http://rspec.info):

    bundle exec rspec

To run the acceptance tests you need to have a recent version of Firefox, since
Capybara is configured to use the Selenium driver with Firefox.

    bundle exec rspec -t js spec/integration

Keep in mind that the acceptance tests are kind of out-of-date. Many of them
will pass, but lots of them are marked as `pending` - the coverage isn't that
good to rely on them.

Finally, Javascript tests are run through [Jasmine](http://jasmine.github.io/).
Start the Jasmine server with:

    bundle exec rake jasmine

And open a browser tab in [http://localhost:8888](http://localhost:8888)


### Docker development

`docker-compose.yml` file build a development environment mounting the current folder and running rails in development environment.

Run the following commands to have a stable development environment.

```
$ docker compose run --rm --no-deps web bundle install
$ docker compose up -d db
$ docker compose run --rm web rake db:setup
$ docker compose up
```

To setup and run test, once the web container is running:

```
$ docker compose exec web bash
root@web_1 $ rake
```

## Deployment

Resource Map uses [Capistrano 3](http://capistranorb.com) to deploy. Capistrano
requires the target server to be already provisioned and correctly setup before
deploying.


## Intercom

Resourcemap supports Intercom as its CRM platform. To load the Intercom chat widget, simply start Resourcemap with the env variable `INTERCOM_APP_ID` set to your Intercom app id (https://www.intercom.com/help/faqs-and-troubleshooting/getting-set-up/where-can-i-find-my-workspace-id-app-id).

Resourcemap will forward any conversation with a logged user identifying them through their email address. Anonymous, unlogged users will also be able to communicate.

If you don't want to use Intercom, you can simply omit `INTERCOM_APP_ID` or set it to `''`.

To test the feature in development, add the `INTERCOM_APP_ID` variable and its value to the `environment` object inside the `web` service in `docker-compose.yml`.

# Upload files using Google Sheets Links

## Overview

Sometimes users won't upload files in the usual way (using the file explorer to select a CSV file), but by providing a Google Spread sheet link.
At server side, link is validated and its content fetched using `Google::Apis::SheetsV4::SheetsService`.
Finally, content of the sheet is written into a CSV file, which is stored same way as the other files (same directory and naming convention).
Therefore, uploading a file through a Google Sheet link yields the same result as downloading the contents of the sheet as CSV and uploading that file in the usual way.

## Setup

Users can only uploads links that belongs to public Google Sheets. Though [Google Sheets API v4](https://developers.google.com/sheets/api/guides/authorizing) doesn't require an `OAuth 2.0 token` to authorize the requests, it does demands an `API_KEY` as a means of authentication. Therefore, in the next subsection we'll review how to create a `GOOGLE_SHEET_API_KEY` in a Project.

### Obtaining a Google Sheet API KEY

1. Create a Google Project or get into an existing one
2. Navigate to `Credentials`
3. Create a new `API_KEY` or select an existing one

At this point we still have to enable our `API_KEY` obtained in step (3) to use `Google Sheets API v4`. Otherwise, if you attempt a request using the `API_KEY` to authenticate yourself (e.g try to read the content of a public spreadsheet), you'll obtain the following error:

```
{
  "error": {
    "code": 403,
    "message": "Google Sheets API has not been used in project {project-id} before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/sheets.googleapis.com/overview?project=project-id then retry"
    "status": "PERMISSION_DENIED",
    "details": [
      ...
    ]
  }
}
```

4. Navigate to https://console.developers.google.com/apis/api/sheets.googleapis.com/overview?project=#{project-id}, as pointed out by the error message. Don't forget to replace _project-id_ with the actual _id_ of the project.
5. Enable `Google Sheets API v4` in your project
6. Wait a few minutes until changes take effect

At this point your `API_KEY` will be ready to authenticate `Google Sheets API v4` requests.

### Setting `GOOGLE_SHEET_API_KEY`

For `DEVELOPMENT`, add `GOOGLE_SHEET_API_KEY` in `settings.local.yml`.
For `PRODUCTION`, add `GOOGLE_SHEET_API_KEY` along with the other variables set in settings.yml
`GOOGLE_SHEET_API_KEY` is used by `SpreadsheetService` class to authenticate `Google Sheets API v4` requests.
 