require 'rails_helper'

RSpec.describe 'All Pages Accessibility', type: :system do
  # Test all view files for accessibility using static file scanning
  # Generated automatically by rails_a11y:install generator
  
  # Helper method to get all view files (non-partials)
  def self.get_all_view_files
    return [] unless defined?(Rails) && Rails.root
    
    view_dir = Rails.root.join('app', 'views')
    return [] unless File.directory?(view_dir)
    
    extensions = %w[erb haml slim]
    view_files = []
    
    extensions.each do |ext|
      # Find all HTML view files (exclude partials that start with _)
      pattern = File.join(view_dir, '**', "*.html.#{ext}")
      Dir.glob(pattern).each do |file|
        # Skip partials (files starting with _)
        next if File.basename(file).start_with?('_')
        # Skip layout files
        next if file.include?('/layouts/')
        view_files << file
      end
    end
    
    view_files.sort
  end
  
  # Format errors with file locations and line numbers
  def format_static_errors(errors, warnings)
    return "" if errors.empty? && warnings.empty?
    
    output = []
    
    # Group errors and warnings by file
    errors_by_file = errors.group_by { |e| e[:file] }
    warnings_by_file = warnings.group_by { |w| w[:file] }
    
    # Show errors first
    if errors.any?
      output.concat(format_issues_section(errors_by_file, "❌", "error"))
    end
    
    # Show warnings if any
    if warnings.any?
      output.concat(format_issues_section(warnings_by_file, "⚠️", "warning"))
    end
    
    output.join("\n")
  end
  
  # Helper method to format a section of issues (errors or warnings)
  def format_issues_section(issues_by_file, emoji, type)
    output = []
    total_count = issues_by_file.values.flatten.length
    
    output << "\n" + "="*70
    output << "#{emoji} #{total_count} #{type}#{'s' if total_count != 1} found"
    output << "="*70
    output << ""
    
    issues_by_file.each_with_index do |(file_path, file_issues), file_index|
      output << "" if file_index > 0
      
      output << "📝 #{file_path} (#{file_issues.length} #{type}#{'s' if file_issues.length != 1})"
      
      file_issues.each do |issue|
        issue_line = "   • #{issue[:type]}"
        
        # Add line number if available
        if issue[:line]
          issue_line += " [Line #{issue[:line]}]"
        end
        
        # Add element identifier
        if issue[:element][:id].present?
          issue_line += " [id: #{issue[:element][:id]}]"
        elsif issue[:element][:href].present?
          href_display = issue[:element][:href].length > 30 ? "#{issue[:element][:href][0..27]}..." : issue[:element][:href]
          issue_line += " [href: #{href_display}]"
        elsif issue[:element][:src].present?
          src_display = issue[:element][:src].length > 30 ? "#{issue[:element][:src][0..27]}..." : issue[:element][:src]
          issue_line += " [src: #{src_display}]"
        end
        
        output << issue_line
      end
    end
    
    output << ""
    output << "="*70
    
    output
  end
  
  # Scan all view files statically
  view_files = get_all_view_files
  
  if view_files.empty?
    it "no view files found to scan" do
      skip "No view files found in app/views"
    end
  else
    view_files.each do |view_file|
      it "scans #{view_file} for accessibility issues" do
        require 'rails_accessibility_testing/static_file_scanner'
        
        scanner = RailsAccessibilityTesting::StaticFileScanner.new(view_file)
        result = scanner.scan
        
        errors = result[:errors] || []
        warnings = result[:warnings] || []
        
        if errors.any? || warnings.any?
          puts format_static_errors(errors, warnings)
          
          if errors.any?
            puts "Found #{errors.length} accessibility error#{'s' if errors.length != 1} in #{view_file}"
          end
        else
          puts "✅ #{view_file}: No errors found"
        end
        
        # Assert that no accessibility errors were found
        expect(errors).to be_empty
      end
    end
  end
end
