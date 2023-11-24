class Repeat < ApplicationRecord
  serialize :rule, IceCube::ValidatedRule
end
