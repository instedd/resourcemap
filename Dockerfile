FROM instedd/nginx-rails:2.1

# Install dependencies
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y libzmq3-dev && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 3 --deployment --without development test

# Default environment settings
ENV POIROT_STDOUT true
ENV POIROT_SUPPRESS_RAILS_LOG true

# Install the application
ADD . /app
# Prevent resque connecting to redis on assets:precompile
RUN mv /app/config/initializers/resque_scheduler.rb /app/config/initializers/resque_scheduler.ignore

# Generate version file
RUN if [ -d .git ]; then git describe --always > VERSION; fi

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production SECRET_KEY_BASE=secret
# Restore resque initialization
RUN mv /app/config/initializers/resque_scheduler.ignore /app/config/initializers/resque_scheduler.rb

# Add config files
ADD docker/runit-web-run /etc/service/web/run
