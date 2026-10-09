class VisualReportPolicy < ApplicationPolicy
  
  def index?
    true
  end

  def items_by_collection?
    true
  end

  def items_in_all_collections?
    true
  end

  def map_items?
    true
  end
end
