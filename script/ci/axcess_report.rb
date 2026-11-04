#!/usr/bin/env ruby
# frozen_string_literal: true

# Accessibility report for an Axcess JSON export (schema v4).
#
# Prints every finding to the terminal, emits GitHub annotations, and writes a
# job summary that links to the uploaded report. Findings never fail the job;
# it exits non-zero only when the scan itself is incomplete, because then there
# is no meaningful report to link to.
#
# Usage: ruby script/ci/axcess_report.rb reports/axcess/axcess.json
#
# Environment:
#   AXCESS_REPORT_URL    link to the uploaded report artifact (optional)
#   A11Y_MIN_PAGES       treat the scan as incomplete below this many pages (default: 3)
#   GITHUB_STEP_SUMMARY  set by GitHub Actions; summary is skipped when absent

require "json"

IMPACT_ORDER = %w[critical serious moderate minor].freeze
MAX_ANNOTATIONS = 50

def annotation_escape(text)
  text.to_s.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
end

def property_escape(text)
  annotation_escape(text).gsub(":", "%3A").gsub(",", "%2C")
end

def github?
  ENV["GITHUB_ACTIONS"] == "true"
end

def group(title)
  puts(github? ? "::group::#{title}" : "== #{title}")
  yield
ensure
  puts "::endgroup::" if github?
end

def impact_of(finding)
  impact = finding["impact"].to_s.downcase
  impact.empty? ? "unrated" : impact
end

json_path = ARGV.fetch(0) { abort "usage: #{$PROGRAM_NAME} path/to/axcess.json" }
abort "Axcess export not found: #{json_path}" unless File.exist?(json_path)

payload = JSON.parse(File.read(json_path))
scan = payload.fetch("scan")
report_url = ENV["AXCESS_REPORT_URL"].to_s

# Written by the workflow next to the JSON export: version=, commit=, ref=.
version_path = File.join(File.dirname(json_path), "axcess-version.txt")
axcess = File.exist?(version_path) ? File.readlines(version_path, chomp: true).to_h { |l| l.split("=", 2) } : {}
min_pages = Integer(ENV.fetch("A11Y_MIN_PAGES", "3"))

findings = payload.fetch("a11y_findings", []).select { |f| f["engine_outcome"].to_s == "failed" }

# Counts per impact, one column per Axcess check (axe, responsive, keyboard...).
pipelines = findings.map { |f| f["pipeline"].to_s.downcase }.uniq.sort_by { |p| p == "axe" ? "" : p }
pipelines = ["axe"] if pipelines.empty?
counts = Hash.new { |h, k| h[k] = Hash.new(0) }
findings.each { |f| counts[impact_of(f)][f["pipeline"].to_s.downcase] += 1 }
impact_rows = IMPACT_ORDER | counts.keys

# axe first, then by impact and frequency.
rules = findings.group_by { |f| [f["pipeline"].to_s, f["rule_id"].to_s, impact_of(f)] }
                .sort_by do |(pipeline, _, impact), list|
                  [pipeline.downcase == "axe" ? 0 : 1, IMPACT_ORDER.index(impact) || IMPACT_ORDER.size, -list.size]
                end

# --- Guard against a crawl that silently scanned nothing -------------------
scan_errors = []
scan_errors << "Axcess ran axe on 0 pages" if scan["axe_pages_scanned"].to_i.zero?
if scan["page_count"].to_i < min_pages
  scan_errors << "Axcess crawled #{scan['page_count'].to_i} page(s); expected at least #{min_pages}"
end

# --- Terminal report --------------------------------------------------------
puts
puts "Axcess accessibility report: #{scan['seed_url']}"
puts "  pages crawled:     #{scan['page_count']}"
puts "  pages axe-scanned: #{scan['axe_pages_scanned']}"
puts "  crawl errors:      #{scan['error_count']}"
puts "  findings:          #{findings.size}"
puts format("    %-10s%s", "impact", pipelines.map { |p| format("%12s", p) }.join)
impact_rows.each do |impact|
  puts format("    %-10s%s", impact, pipelines.map { |p| format("%12d", counts[impact][p]) }.join)
end
puts

rules.each do |(pipeline, rule_id, impact), list|
  sample = list.first
  group("#{impact.upcase.ljust(8)} #{rule_id} [#{pipeline}] — #{list.size} occurrence(s)") do
    puts "  #{sample['help']}"
    puts "  WCAG: #{sample['wcag_scs'] || sample['wcag_sc'] || 'n/a'} (level #{sample['wcag_level'] || 'n/a'})"
    puts "  More: #{sample['help_url']}" unless sample["help_url"].to_s.empty?
    list.each do |f|
      puts "  - #{f['page_url']}"
      puts "      target:   #{f['target_display'] || f['target_selector']}"
      summary = f["failure_summary"].to_s.lines.map(&:strip).reject(&:empty?).first(2).join(" ")
      puts "      problem:  #{summary}" unless summary.empty?
      puts "      revealed: #{f['revealed_by']}" if f["revealed_by"]
    end
  end
end

# --- GitHub annotations -----------------------------------------------------
if github?
  annotated = 0
  rules.each do |(pipeline, rule_id, impact), list|
    list.each do |f|
      break if annotated >= MAX_ANNOTATIONS

      title = property_escape("#{pipeline} #{rule_id} (#{impact})")
      message = annotation_escape("#{f['help']} — #{f['page_url']} #{f['target_selector']}")
      puts "::warning title=#{title}::#{message}"
      annotated += 1
    end
  end
end

scan_errors.each { |e| puts(github? ? "::error title=Axcess scan incomplete::#{annotation_escape(e)}" : "ERROR: #{e}") }
puts
puts "Accessibility report: #{findings.size} finding(s) on #{scan['page_count']} page(s)"
puts "Full report: #{report_url}" unless report_url.empty?

# --- Job summary ------------------------------------------------------------
if (summary_path = ENV["GITHUB_STEP_SUMMARY"])
  File.open(summary_path, "a") do |out|
    out.puts "## Accessibility report (Axcess)"
    out.puts
    unless report_url.empty?
      out.puts "**[Download the full report](#{report_url})** (JSON, Markdown, XLSX, CSV)"
      out.puts
    end
    if axcess["commit"].to_s.size >= 7
      out.puts "Scanned with Axcess #{axcess['version']} " \
               "([lsa-mis/axcess@#{axcess['commit'][0, 7]}](https://github.com/lsa-mis/axcess/commit/#{axcess['commit']}))"
      out.puts
    end
    out.puts "Seed `#{scan['seed_url']}` · #{scan['page_count']} pages crawled · " \
             "#{scan['axe_pages_scanned']} axe-scanned · #{findings.size} findings"
    scan_errors.each { |e| out.puts "\n> **Scan incomplete:** #{e}" }
    out.puts
    out.puts "| Impact | #{pipelines.join(' | ')} |"
    out.puts "| --- |#{' ---: |' * pipelines.size}"
    impact_rows.each do |impact|
      out.puts "| #{impact} | #{pipelines.map { |p| counts[impact][p] }.join(' | ')} |"
    end
    if rules.any?
      out.puts
      out.puts "| Rule | Impact | Check | Occurrences | Pages |"
      out.puts "| --- | --- | --- | ---: | ---: |"
      rules.first(25).each do |(pipeline, rule_id, impact), list|
        link = list.first["help_url"].to_s.empty? ? "`#{rule_id}`" : "[`#{rule_id}`](#{list.first['help_url']})"
        out.puts "| #{link} | #{impact} | #{pipeline} | #{list.size} | #{list.map { |f| f['page_url'] }.uniq.size} |"
      end
      out.puts "\n_Showing 25 of #{rules.size} rules._" if rules.size > 25
    end
    out.puts
  end
end

exit(scan_errors.any? ? 1 : 0)
