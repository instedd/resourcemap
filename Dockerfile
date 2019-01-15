FROM ruby:2.1

# Install dependencies
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y libzmq3-dev nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 3 --deployment --without development test

# Default environment settings
ENV POIROT_STDOUT true
ENV POIROT_SUPPRESS_RAILS_LOG true
ENV LOG_TO_STDOUT true
ENV INSTEDD_THEME //theme.instedd.org
ENV RAILS_ENV production
ENV WEB_BIND_URI tcp://0.0.0.0:80
ENV PUMA_TAG resourcemap
ENV WEB_PUMA_FLAGS ""

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
ADD docker/*.yml /app/config/

# Environment variables setup
# Guisso
# GUISSO_ENABLED GUISSO_URL GUISSO_CLIENT_ID GUISSO_CLIENT_SECRET

CMD exec puma -e $RAILS_ENV -b $WEB_BIND_URI --tag $PUMA_TAG $WEB_PUMA_FLAGS
