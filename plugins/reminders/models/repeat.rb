class Repeat < ActiveRecord::Base
  serialize :rule, IceCube::ValidatedRule
end
