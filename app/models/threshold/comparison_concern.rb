module Threshold::ComparisonConcern
  extend ActiveSupport::Concern

  def eq(a, b)
    a == b
  end

  def lt(a, b)
    a < b
  end

  def lte(a, b)
    lt(a, b) || eq(a, b)
  end

  def gt(a, b)
    a > b
  end

  def gte(a, b)
    gt(a, b) || eq(a, b)
  end
end
