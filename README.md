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
$ docker-compose run --rm --no-deps web bundle install
$ docker-compose up -d db
$ docker-compose run --rm web rake db:setup
$ docker-compose up
```

To setup and run test, once the web container is running:

```
$ docker-compose exec web bash
root@web_1 $ rake
```

## Deployment

Resource Map uses [Capistrano 3](http://capistranorb.com) to deploy. Capistrano
requires the target server to be already provisioned and correctly setup before
deploying.

The [Vagrant](http://vagrantup.com) configuration file contains two different
virtual machines for testing, which are provisioned for deployment using
Capistrano. One is setup to install `RVM` and the other `rbenv`. Check the
`Vagrantfile` and the configuration files and scripts in `config/vagrant` for a
sample provisioning.

The Capistrano stages `vagrant-rvm` and `vagrant-rbenv` can be used to deploy
Resource Map to the virtual machines. Only one of the virtual machines can be
running at the same time, since per configuration both forward the 80 port to
the host's 8080.

## Intercom

Resourcemap supports Intercom as its CRM platform. To load the Intercom chat widget, simply start Resourcemap with the env variable `INTERCOM_APP_ID` set to your Intercom app id (https://www.intercom.com/help/faqs-and-troubleshooting/getting-set-up/where-can-i-find-my-workspace-id-app-id).

Resourcemap will forward any conversation with a logged user identifying them through their email address. Anonymous, unlogged users will also be able to communicate.

If you don't want to use Intercom, you can simply omit `INTERCOM_APP_ID` or set it to `''`.

To test the feature in development, add the `INTERCOM_APP_ID` variable and its value to the `environment` object inside the `web` service in `docker-compose.yml`.