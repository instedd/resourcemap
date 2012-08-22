class <%= class_name %>Controller < ApplicationController
  before_filter :authenticate_user!

end