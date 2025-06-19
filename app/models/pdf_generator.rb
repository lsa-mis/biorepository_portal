class PdfGenerator
  require 'prawn'
  include ActionView::Helpers::SanitizeHelper 

  def initialize(loan_answers, checkout_items)
    @loan_answers = loan_answers
    @checkout_items = checkout_items
  end

  # def self.generate_pdf(content)
  #   Prawn::Document.new do
  #     text "Hello, World!"
  #     text content
  #   end.render
  # end

  def generate_pdf_content
    Prawn::Document.new do |pdf|
      # Register the external font
      pdf.font_families.update('Montserrat' => {
        light: Rails.root.join('app/assets/stylesheets/Montserrat-Light.ttf'),
        normal: Rails.root.join('app/assets/stylesheets/Montserrat-Regular.ttf'),
        medium: Rails.root.join('app/assets/stylesheets/Montserrat-Medium.ttf'),
        bold: Rails.root.join('app/assets/stylesheets/Montserrat-Black.ttf'),
      })
      pdf.font('Montserrat') # Use the registered font
      pdf.text "#{@loan_answers.first.user.email} - #{Date.today}", size: 24, align: :center
      pdf.move_down 10
      @loan_answers.each_with_index do |answer, index|
        pdf.text "#{answer.loan_question.question}", size: 12, style: :medium
        pdf.text "#{strip_tags(answer.answer.to_s)}", size: 12

        pdf.move_down 5
      end

      # Add checkout items table if present
      if defined?(@checkout_items) && @checkout_items.present?
        pdf.start_new_page
        pdf.text "Checkout Items", size: 16, style: :bold
        # Parse @checkout_items string into rows
        items = @checkout_items.split(/\.(\s+|$)/).map(&:strip).reject(&:blank?)
        table_data = [["Collection", "Occurrence ID", "Preparation", "Barcode", "Description", "Count"]]
        items.each do |item_str|
          # Example: "Division, occurrenceID: 123; preparation: X barcode: 456, description: foo, count: 2"
          collection = item_str[/^([^,]+)/, 1]&.strip
          occurrence_id = item_str[/occurrenceID:\s*([^;]+)/, 1]&.strip
          preparation = item_str[/preparation:\s*([^,;]+)/, 1]&.strip
          barcode = item_str[/barcode:\s*([^,;]+)/, 1]&.strip
          description = item_str[/description:\s*([^,;]+)/, 1]&.strip
          count = item_str[/count:\s*([^,;]+)/, 1]&.strip
          table_data << [collection, occurrence_id, preparation, barcode, description, count]
        end
        pdf.table(table_data, header: true, width: pdf.bounds.width, cell_style: { size: 10 })
      end

    end.render
  end
end
