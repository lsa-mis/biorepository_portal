#!/usr/bin/env ruby
# frozen_string_literal: true

# Accessibility report for an Axcess JSON export (schema v4).
#
# Prints the findings as plain text, grouped into issues: one issue is one rule
# failing on one element, so a problem repeated on 35 pages reads once, with
# the pages listed. Issues come most severe first, and a summary comes last,
# where the terminal leaves you. The output has no tables, box drawing, color
# or percent-encoded paths, so it reads the same in a screen reader as on
# screen. In GitHub Actions it also folds each issue into a log group, adds
# one annotation per issue, and writes a job summary that links to the
# uploaded report. Findings never fail the job; it exits non-zero only when
# the scan itself is incomplete, because then there is no meaningful report.
#
# Usage: ruby script/ci/axcess_report.rb reports/axcess/axcess.json
#
# Environment:
#   AXCESS_REPORT_URL      link to the uploaded report artifact (optional)
#   A11Y_MIN_PAGES         treat the scan as incomplete below this many pages (default: 3)
#   A11Y_REPORT_ALL_PAGES  set to 1 to list every page of each issue (default: the first 5)
#   GITHUB_STEP_SUMMARY    set by GitHub Actions; summary is skipped when absent

require "cgi"
require "json"
require "uri"

IMPACT_ORDER = %w[critical serious moderate minor].freeze
MAX_ANNOTATIONS = 50
PAGES_SHOWN = ENV["A11Y_REPORT_ALL_PAGES"] == "1" ? nil : 5
ELEMENTS_SHOWN = 5

def annotation_escape(text)
  text.to_s.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
end

def property_escape(text)
  annotation_escape(text).gsub(":", "%3A").gsub(",", "%2C")
end

def github?
  ENV["GITHUB_ACTIONS"] == "true"
end

# A heading line, folded into a collapsible group in the GitHub Actions log.
def group(title)
  puts(github? ? "::group::#{title}" : title)
  yield
ensure
  puts "::endgroup::" if github?
end

def impact_of(finding)
  impact = finding["impact"].to_s.downcase
  impact.empty? ? "unrated" : impact
end

def plural(count, word)
  "#{count} #{word}#{'s' unless count == 1}"
end

# "a, b, c, and 4 more" when there are more items than the limit.
def list_with_more(items, limit)
  shown = limit ? items.first(limit) : items
  rest = items.size - shown.size
  rest.positive? ? "#{shown.join(', ')}, and #{rest} more" : shown.join(", ")
end

# A page URL as a short, readable path: no scheme or host, and no %2F escapes,
# which screen readers spell out character by character.
def page_path(url, origin)
  path = url.to_s.delete_prefix(origin)
  URI.decode_uri_component(path.empty? ? "/" : path)
rescue ArgumentError
  url.to_s
end

# The text inside an element, from its HTML snippet.
def element_text(html)
  CGI.unescapeHTML(html.to_s.gsub(/<[^>]*>/, " ")).split.join(" ")
end

def sentence(text)
  text.match?(/[.!?:]\z/) ? text : "#{text}."
end

# The failure summary as sentences. axe lists its checks under "Fix any of the
# following:" (one fix is enough) or "Fix all of the following:"; a single
# check is shown alone, and several are numbered under a plain-language intro.
def problem_text(finding)
  sections = []
  finding["failure_summary"].to_s.each_line do |raw|
    line = raw.strip
    next if line.empty?

    if (lead = line.match(/\AFix (any|all) of the following:\z/))
      sections << { mode: lead[1], items: [] }
    else
      sections << { mode: nil, items: [] } if sections.empty?
      sections.last[:items] << sentence(line)
    end
  end
  sections.reject { |s| s[:items].empty? }.map do |s|
    next s[:items].join(" ") if s[:mode].nil? || s[:items].size == 1

    intro = s[:mode] == "any" ? "Any one of these fixes it:" : "Fix all of these:"
    "#{intro} #{s[:items].each.with_index(1).map { |item, i| "(#{i}) #{item}" }.join(' ')}"
  end.join(" ")
end

def wcag_text(finding)
  criteria = finding["wcag_scs"] || finding["wcag_sc"]
  return "No WCAG criterion listed." if criteria.to_s.empty?

  level = finding["wcag_level"].to_s
  "WCAG #{Array(criteria).join(', ')}#{" (level #{level})" unless level.empty?}."
end

def check_name(pipeline)
  pipeline == "axe" ? "axe-core" : "the Axcess #{pipeline} check"
end

# A path relative to the current directory when it is inside it.
def display_path(path)
  full = File.expand_path(path)
  full.start_with?("#{Dir.pwd}/") ? full.delete_prefix("#{Dir.pwd}/") : full
end

json_path = ARGV.fetch(0) { abort "usage: #{$PROGRAM_NAME} path/to/axcess.json" }
abort "Axcess export not found: #{json_path}" unless File.exist?(json_path)

payload = JSON.parse(File.read(json_path))
scan = payload.fetch("scan")
report_url = ENV["AXCESS_REPORT_URL"].to_s
origin = scan["seed_url"].to_s[%r{\A[a-z][a-z0-9+.-]*://[^/?#]+}i].to_s
page_count = scan["page_count"].to_i

# Written by the workflow next to the JSON export: version=, commit=, ref=.
version_path = File.join(File.dirname(json_path), "axcess-version.txt")
axcess = File.exist?(version_path) ? File.readlines(version_path, chomp: true).to_h { |l| l.split("=", 2) } : {}
min_pages = Integer(ENV.fetch("A11Y_MIN_PAGES", "3"))

findings = payload.fetch("a11y_findings", []).select { |f| f["engine_outcome"].to_s == "failed" }

# Counts per impact, one column per Axcess check (axe, responsive, keyboard...),
# for the job summary.
pipelines = findings.map { |f| f["pipeline"].to_s.downcase }.uniq.sort_by { |p| p == "axe" ? "" : p }
pipelines = ["axe"] if pipelines.empty?
counts = Hash.new { |h, k| h[k] = Hash.new(0) }
findings.each { |f| counts[impact_of(f)][f["pipeline"].to_s.downcase] += 1 }
impact_rows = IMPACT_ORDER | counts.keys

# Rules for the job summary: axe first, then by impact and frequency.
rules = findings.group_by { |f| [f["pipeline"].to_s, f["rule_id"].to_s, impact_of(f)] }
                .sort_by do |(pipeline, _, impact), list|
                  [pipeline.downcase == "axe" ? 0 : 1, IMPACT_ORDER.index(impact) || IMPACT_ORDER.size, -list.size]
                end

# Issues for the terminal: one rule failing on one element. Most severe first,
# then the ones on the most pages.
issues = findings.group_by { |f| [impact_of(f), f["pipeline"].to_s, f["rule_id"].to_s, f["target_selector"].to_s] }
                 .map do |(impact, pipeline, rule_id, selector), list|
                   { impact:, pipeline:, rule_id:, selector:, list:, pages: list.map { |f| f["page_url"].to_s }.uniq }
                 end
issues.sort_by! { |i| [IMPACT_ORDER.index(i[:impact]) || IMPACT_ORDER.size, -i[:pages].size, i[:rule_id], i[:selector]] }

# --- Guard against a crawl that silently scanned nothing -------------------
scan_errors = []
scan_errors << "Axcess ran axe on 0 pages" if scan["axe_pages_scanned"].to_i.zero?
if page_count < min_pages
  scan_errors << "Axcess crawled #{plural(page_count, 'page')}; expected at least #{min_pages}"
end

# --- Terminal report --------------------------------------------------------
crawl_errors = scan["error_count"].to_i
puts
puts "Accessibility report for #{scan['seed_url']}"
puts "Scanned #{plural(page_count, 'page')}, #{scan['axe_pages_scanned'].to_i} of them with axe. " \
     "#{crawl_errors.zero? ? 'No crawl errors' : plural(crawl_errors, 'crawl error')}."
if issues.any?
  puts "#{plural(findings.size, 'finding')}, grouped into #{plural(issues.size, 'issue')} " \
       "(one issue is one rule failing on one element), most severe first."
end

issues.each.with_index(1) do |issue, number|
  sample = issue[:list].first
  title = sample["help"].to_s.strip.delete_suffix(".")
  title = issue[:rule_id] if title.empty?
  paths = issue[:pages].map { |url| page_path(url, origin) }
  texts = issue[:list].map { |f| element_text(f["html_snippet"]) }.reject(&:empty?).uniq
  element = issue[:selector].empty? ? "not recorded" : issue[:selector]
  if texts.size == 1
    element += %(, text "#{texts.first}")
  elsif texts.size > 1
    element += ", #{texts.size} elements: #{list_with_more(texts.map { |t| %("#{t}") }, ELEMENTS_SHOWN)}"
  end
  problem = problem_text(sample)
  revealed = issue[:list].map { |f| f["revealed_by"] }.compact.uniq

  puts
  group("Issue #{number} of #{issues.size}: #{issue[:impact].capitalize}. #{title}.") do
    puts "  Element: #{element}"
    puts "  #{paths.size == 1 ? 'Page' : "On #{paths.size} pages"}: #{list_with_more(paths, PAGES_SHOWN)}"
    puts "  Problem#{" on #{paths.first}" if paths.size > 1}: #{problem}" unless problem.empty?
    puts "  Revealed by: #{list_with_more(revealed, 3)}" if revealed.any?
    puts "  #{wcag_text(sample)} Rule #{issue[:rule_id]}, from #{check_name(issue[:pipeline])}."
    puts "  More: #{sample['help_url']}" unless sample["help_url"].to_s.empty?
  end
end

# --- GitHub annotations: one per issue -------------------------------------
if github?
  issues.first(MAX_ANNOTATIONS).each do |issue|
    sample = issue[:list].first
    title = property_escape("#{issue[:impact].capitalize}: #{sample['help'].to_s.strip.delete_suffix('.')}")
    pages = list_with_more(issue[:pages].map { |url| page_path(url, origin) }, 5)
    message = annotation_escape("#{issue[:rule_id]} on #{issue[:selector]}, #{plural(issue[:pages].size, 'page')}: #{pages}")
    puts "::warning title=#{title}::#{message}"
  end
end

# --- Summary, last so it is what the terminal shows when the run ends -------
puts
puts "Summary"
if issues.any?
  puts "  #{plural(issues.size, 'issue')} from #{plural(findings.size, 'finding')} on #{plural(page_count, 'page')}."
  (IMPACT_ORDER | issues.map { |i| i[:impact] }).each do |impact|
    group_issues = issues.select { |i| i[:impact] == impact }
    next if group_issues.empty?

    puts "  #{impact.capitalize}: #{plural(group_issues.size, 'issue')}, " \
         "#{plural(group_issues.sum { |i| i[:list].size }, 'finding')}."
  end
else
  puts "  No findings on #{plural(page_count, 'page')}."
end
scan_errors.each do |e|
  puts "  Scan incomplete: #{e}."
  puts "::error title=Axcess scan incomplete::#{annotation_escape(e)}" if github?
end
if report_url.empty?
  report_dir = display_path(File.dirname(json_path))
  puts "  Full report: #{report_dir}/axcess.md (also axcess.xlsx, axcess.csv and axcess.json)."
  if PAGES_SHOWN && issues.any? { |i| i[:pages].size > PAGES_SHOWN }
    puts "  To list every page of each issue: A11Y_REPORT_ALL_PAGES=1 ruby #{display_path(__FILE__)} " \
         "#{display_path(json_path)}"
  end
else
  puts "  Full report: #{report_url}"
end

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
