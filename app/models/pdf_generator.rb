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

  def initialize(user, loan_answers, checkout_items, collection_answers = {})
    @loan_answers = loan_answers
    @checkout_items = checkout_items
    @collection_answers = collection_answers
    @user = user
  end

  def generate_pdf_content
    Prawn::Document.new do |pdf|
      register_fonts(pdf)
      pdf.font('Montserrat')

      # Title
      pdf.text "#{@user&.name_with_email}", size: 20, style: :bold, align: :center
      pdf.text "#{Date.today.strftime("%B %d, %Y")}", size: 20, style: :bold, align: :center
      pdf.move_down 20

      # Section: User Information
      pdf.text "User Information", size: 16, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      render_user_information(pdf, @user)

      # Section: Generic Loan Questions
      pdf.text "Generic Loan Questions", size: 16, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      render_question_answers(pdf, @loan_answers)

      # Section: Collection-specific Questions
      @collection_answers.each do |collection, qa_hash|
        pdf.start_new_page
        pdf.text "Collection: #{collection.division}", size: 16, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        render_question_answers(pdf, qa_hash)
      end

      # Section: Checkout Items
      if @checkout_items.present?
        pdf.start_new_page
        pdf.text "Checkout Items", size: 16, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        # items = @checkout_items.split(/\.(?:\s+|$)/).map(&:strip).reject(&:blank?)
        table_data = [["Collection", "Occurrence ID", "Preparation", "Barcode", "Description", "Count"]]

        @checkout_items.each do |item_str|
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

  def render_question_answers(pdf, question_answer_pairs)
    question_answer_pairs.each do |question, answer|
      number = question.position || "(unpositioned)"
      pdf.text "#{number}. #{question.question}", size: 12, style: :medium

      if question.question_type == "attachment"
        attachment_status = answer&.attachment&.attached? ? "File attached" : "No file attached"
        pdf.text attachment_status, size: 11
      else
        raw_text = answer&.answer.to_s
        stripped_text = strip_tags(raw_text).strip
        response_text = stripped_text.presence || NO_RESPONSE_PLACEHOLDER
        pdf.text response_text, size: 11
      end

      pdf.move_down 8
    end
  end

  def render_user_information(pdf, user)
    pdf.text "Name: #{user.display_name}", size: 12
    pdf.text "Email: #{user.email}", size: 12
    pdf.text "Affiliation: #{user.affiliation}", size: 12
    pdf.text "ORCID: #{user.orcid}", size: 12 if user.orcid.present?
    pdf.move_down 10
  end

end
