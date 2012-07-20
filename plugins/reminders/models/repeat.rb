class Repeat < ActiveRecord::Base
  serialize :rule, IceCube::Rule
end
