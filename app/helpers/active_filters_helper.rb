module ActiveFiltersHelper
  def format_active_filters(params)
    return [] unless params[:q].present?

    q = params[:q]
    filters = []

    if q[:collection_id_in].present?
      collection_ids = Array.wrap(q[:collection_id_in])
      collection_names = Collection.where(id: collection_ids).pluck(:division)
      filters += collection_names.map { |name| "#{name}" }
    end

    if q[:dynamic_fields].present?
      dynamic_fields = q[:dynamic_fields].is_a?(Hash) ? q[:dynamic_fields].values : q[:dynamic_fields]

      dynamic_fields.each do |field_hash|
        next unless field_hash.is_a?(Hash)
        next if field_hash["field"].blank? || field_hash["value"].blank?

        label = field_hash["field"].gsub(/_i_cont|_eq|_gteq|_lteq/, '').titleize
        op = case field_hash["field"]
             when /_i_cont/ then "contains"
             when /_eq/     then "equals"
             when /_gteq/   then "≥"
             when /_lteq/   then "≤"
             else "is"
             end

        filters << "#{label} #{op} #{field_hash['value']}"
      end
    end


    filters
    
  end
end
