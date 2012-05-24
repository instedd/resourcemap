module Threshold::ComparisonConcern
  extend ActiveSupport::Concern

  def eq(a, b)
    a == b
  end

  def lt(a, b)
    a < b
  end

  def lte(a, b)
    a <= b
  end

  def gt(a, b)
    a > b
  end

  def gte(a, b)
    a >= b
  end
end
