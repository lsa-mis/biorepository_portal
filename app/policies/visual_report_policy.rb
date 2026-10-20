class VisualReportPolicy < ApplicationPolicy
  
  def index?
    true
  end

  def map_items?
    true
  end
end
