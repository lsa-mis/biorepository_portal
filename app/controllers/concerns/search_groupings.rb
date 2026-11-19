module SearchGroupings
  extend ActiveSupport::Concern

  private

    # Converts advanced search groupings ({ "0" => { "0" => { "field" => f, "value" => v } } })
    # into the ransack format ({ "0" => { f => [v], "m" => "or" } })
    def transform_search_groupings
      if params[:q] && params[:q][:groupings]
        transformed_groupings = {}
        params[:q][:groupings].each do |group_index, group_data|
          group = {}
          group_data.each do |field_index, field_data|
            
            next if field_index == "m"
            next if field_data.class == Array
            next unless field_data["field"].present? && field_data["value"].present?

            field = field_data["field"]
            value = field_data["value"]

            group[field] ||= []
            group[field] << value
          end

          # Wrap group in an indexed key
          transformed_groupings[group_index] = group
          # Add matcher if present
          transformed_groupings[group_index]["m"] = group_data["m"].presence || "or"
        end
        params[:q][:groupings] = ActionController::Parameters.new(transformed_groupings).permit!
      end
    end

    # Groups the transformed groupings into [{ field:, value: }] lists for format_active_filters
    def setup_dynamic_fields
      @dynamic_fields = []
      return unless params.dig(:q, :groupings).present?
      
      params.dig(:q, :groupings).each do |group_num, values|
        group_pairs = []
        values.each do |field, val|
          
          next if field == "m" || val.blank?
          group_pairs << { field: field, value: val }
        end
        @dynamic_fields << group_pairs unless group_pairs.empty?
      end
    end
end
