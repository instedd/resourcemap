class ActivitiesController < ApplicationController
  expose(:activities) { current_user.activities }
end
