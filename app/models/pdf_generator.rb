class PdfGenerator
  require 'prawn'
  include ActionView::Helpers::SanitizeHelper 

  NO_RESPONSE_PLACEHOLDER = '—'.freeze
  FONT_FAMILY = {
    'Montserrat' => {
      light: Rails.root.join('app/assets/stylesheets/Montserrat-Light.ttf'),
      normal: Rails.root.join('app/assets/stylesheets/Montserrat-Regular.ttf'),
      medium: Rails.root.join('app/assets/stylesheets/Montserrat-Medium.ttf'),
      bold: Rails.root.join('app/assets/stylesheets/Montserrat-Black.ttf')
    }
  }.freeze

  def initialize(loan_answers, checkout_items, collection_answers = {})
    @loan_answers = loan_answers
    @checkout_items = checkout_items
    @collection_answers = collection_answers
  end

  # def self.generate_pdf(content)
  #   Prawn::Document.new do
  #     text "Hello, World!"
  #     text content
  #   end.render
  # end

  def generate_pdf_content
    Prawn::Document.new do |pdf|
      register_fonts(pdf)
      pdf.font('Montserrat')

      # Title
      pdf.text "#{@loan_answers.first[1].user&.first_name} #{@loan_answers.first[1].user&.last_name} - #{Date.today.strftime("%B %d, %Y")}",
              size: 20, style: :bold, align: :center
      pdf.move_down 20

      # Section: Generic Loan Questions
      pdf.text "Generic Loan Questions", size: 16, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      @loan_answers.each do |question, answer|
        pdf.text "#{question.position}. #{question.question}", size: 12, style: :medium
        pdf.text "#{strip_tags(answer&.answer.to_s.presence || NO_RESPONSE_PLACEHOLDER)}", size: 11
      end

      # Section: Collection-specific Questions
      @collection_answers.each do |collection, qa_hash|
        pdf.start_new_page
        pdf.text "Collection: #{collection.division}", size: 16, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        qa_hash.each_with_index do |(question, answer), i|
          pdf.text "#{i + 1}. #{question.question}", size: 12, style: :medium
          pdf.text "#{strip_tags(answer&.answer.to_s.presence || NO_RESPONSE_PLACEHOLDER)}", size: 11
          pdf.move_down 8
        end
      end

      # Section: Checkout Items
      if @checkout_items.present?
        pdf.start_new_page
        pdf.text "Checkout Items", size: 16, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        items = @checkout_items.split(/\.(?:\s+|$)/).map(&:strip).reject(&:blank?)
        table_data = [["Collection", "Occurrence ID", "Preparation", "Barcode", "Description", "Count"]]

        items.each do |item_str|
          collection   = item_str[/^([^,]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER
          occurrence_id = item_str[/occurrenceID:\s*([^;]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER
          preparation  = item_str[/preparation:\s*([^,;]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER
          barcode      = item_str[/barcode:\s*([^,;]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER
          description  = item_str[/description:\s*([^,;]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER
          count        = item_str[/count:\s*([^,;]+)/, 1]&.strip || NO_RESPONSE_PLACEHOLDER

          table_data << [collection, occurrence_id, preparation, barcode, description, count]
        end

        pdf.table(table_data,
          header: true,
          width: pdf.bounds.width,
          cell_style: { size: 9, padding: 6 }) do
            row(0).font_style = :bold
            row(0).background_color = 'eeeeee'
          end
      end
    end.render
  end

  private

  def register_fonts(pdf)
    pdf.font_families.update(FONT_FAMILY)
  end
end
