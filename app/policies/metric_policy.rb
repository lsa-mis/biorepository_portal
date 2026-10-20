class MetricPolicy < ApplicationPolicy
  
  def index?
    true
  end

  def map_items?
    true
  end
end
