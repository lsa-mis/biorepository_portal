#!/usr/bin/env ruby
# frozen_string_literal: true

# Accessibility gate for an Axcess JSON export (schema v4).
#
# Prints every finding to the terminal, emits GitHub annotations, writes a job
# summary, and exits non-zero when blocking findings exist in enforce mode.
#
# Usage: ruby script/ci/axcess_gate.rb reports/axcess/axcess.json
#
# Environment:
#   A11Y_ENFORCEMENT     enforce (default) | advisory
#   A11Y_FAIL_ON         comma-separated impacts that block (default: critical,serious)
#   A11Y_GATE_PIPELINES  comma-separated pipelines that can block (default: axe)
#   A11Y_MIN_PAGES       fail if the crawl reached fewer pages (default: 3)
#   GITHUB_STEP_SUMMARY  set by GitHub Actions; summary is skipped when absent

require "json"

IMPACT_ORDER = %w[critical serious moderate minor].freeze
MAX_ANNOTATIONS = 50

def env_list(name, default)
  ENV.fetch(name, default).split(",").map { |v| v.strip.downcase }.reject(&:empty?)
end

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

json_path = ARGV.fetch(0) { abort "usage: #{$PROGRAM_NAME} path/to/axcess.json" }
abort "Axcess export not found: #{json_path}" unless File.exist?(json_path)

payload = JSON.parse(File.read(json_path))
scan = payload.fetch("scan")
enforce = ENV.fetch("A11Y_ENFORCEMENT", "enforce").downcase != "advisory"
fail_on = env_list("A11Y_FAIL_ON", "critical,serious")
gate_pipelines = env_list("A11Y_GATE_PIPELINES", "axe")
min_pages = Integer(ENV.fetch("A11Y_MIN_PAGES", "3"))

findings = payload.fetch("a11y_findings", []).select { |f| f["engine_outcome"].to_s == "failed" }
blocking = findings.select do |f|
  fail_on.include?(f["impact"].to_s.downcase) && gate_pipelines.include?(f["pipeline"].to_s.downcase)
end

def impact_of(finding)
  impact = finding["impact"].to_s.downcase
  impact.empty? ? "unrated" : impact
end

# Counts per impact, split into pipelines that can block and report-only ones.
gated_counts = Hash.new(0)
other_counts = Hash.new(0)
findings.each do |f|
  counts = gate_pipelines.include?(f["pipeline"].to_s.downcase) ? gated_counts : other_counts
  counts[impact_of(f)] += 1
end
impact_rows = IMPACT_ORDER | gated_counts.keys | other_counts.keys
gated_label = gate_pipelines.join("/")
other_pipelines = findings.map { |f| f["pipeline"].to_s.downcase }.uniq - gate_pipelines
other_label = other_pipelines.empty? ? "other" : other_pipelines.join("/")

# Blocking-capable pipelines first, then by impact and frequency.
rules = findings.group_by { |f| [f["pipeline"].to_s, f["rule_id"].to_s, impact_of(f)] }
                .sort_by do |(pipeline, _, impact), list|
                  [gate_pipelines.include?(pipeline.downcase) ? 0 : 1,
                   IMPACT_ORDER.index(impact) || IMPACT_ORDER.size, -list.size]
                end

# --- Guard against a crawl that silently scanned nothing -------------------
guard_errors = []
guard_errors << "Axcess ran axe on 0 pages" if scan["axe_pages_scanned"].to_i.zero?
if scan["page_count"].to_i < min_pages
  guard_errors << "Axcess crawled #{scan['page_count'].to_i} page(s); expected at least #{min_pages}"
end

# --- Terminal report --------------------------------------------------------
puts
puts "Axcess accessibility scan: #{scan['seed_url']}"
puts "  pages crawled:     #{scan['page_count']}"
puts "  pages axe-scanned: #{scan['axe_pages_scanned']}"
puts "  crawl errors:      #{scan['error_count']}"
puts "  findings (failed): #{findings.size}"
puts format("    %-10s %8s %10s", "impact", gated_label, "#{other_label} (report only)")
impact_rows.each do |impact|
  marker = fail_on.include?(impact) ? "  <- blocks" : ""
  puts format("    %-10s %8d %10d%s", impact, gated_counts[impact], other_counts[impact], marker)
end
puts "  blocking findings: #{blocking.size}"
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

      level = blocking.include?(f) ? "error" : "warning"
      title = property_escape("#{pipeline} #{rule_id} (#{impact})")
      message = annotation_escape("#{f['help']} — #{f['page_url']} #{f['target_selector']}")
      puts "::#{level} title=#{title}::#{message}"
      annotated += 1
    end
  end
  remaining = findings.size - annotated
  puts "::notice::#{remaining} more finding(s) not annotated; see the job log and report artifact" if remaining.positive?
end

# --- Verdict ----------------------------------------------------------------
failed = guard_errors.any? || (enforce && blocking.any?)
verdict =
  if guard_errors.any? then "FAILED — scan incomplete"
  elsif blocking.any? && enforce then "FAILED — #{blocking.size} blocking finding(s) (#{fail_on.join(', ')})"
  elsif blocking.any? then "PASSED (advisory) — #{blocking.size} blocking finding(s) not enforced"
  else "PASSED — no #{fail_on.join('/')} findings"
  end

guard_errors.each { |e| puts(github? ? "::error title=Axcess scan incomplete::#{annotation_escape(e)}" : "ERROR: #{e}") }
puts "::warning::Accessibility gate is in advisory mode; blocking findings will not fail the build" if !enforce && github?
puts
puts "Accessibility gate: #{verdict}"

# --- Job summary ------------------------------------------------------------
if (summary_path = ENV["GITHUB_STEP_SUMMARY"])
  File.open(summary_path, "a") do |out|
    out.puts "## Accessibility gate (Axcess): #{verdict}"
    out.puts
    out.puts "Seed `#{scan['seed_url']}` · #{scan['page_count']} pages crawled · " \
             "#{scan['axe_pages_scanned']} axe-scanned · mode `#{enforce ? 'enforce' : 'advisory'}` · " \
             "blocking impacts `#{fail_on.join(', ')}`"
    guard_errors.each { |e| out.puts "\n> **Error:** #{e}" }
    out.puts
    out.puts "| Impact | #{gated_label} (can block) | #{other_label} (report only) |"
    out.puts "| --- | ---: | ---: |"
    impact_rows.each do |impact|
      label = fail_on.include?(impact) ? "**#{impact}** (blocking)" : impact
      out.puts "| #{label} | #{gated_counts[impact]} | #{other_counts[impact]} |"
    end
    if rules.any?
      out.puts
      out.puts "| Rule | Impact | Pipeline | Occurrences | Pages |"
      out.puts "| --- | --- | --- | ---: | ---: |"
      rules.first(25).each do |(pipeline, rule_id, impact), list|
        link = list.first["help_url"].to_s.empty? ? "`#{rule_id}`" : "[`#{rule_id}`](#{list.first['help_url']})"
        out.puts "| #{link} | #{impact} | #{pipeline} | #{list.size} | #{list.map { |f| f['page_url'] }.uniq.size} |"
      end
      out.puts "\n_Showing 25 of #{rules.size} rules._" if rules.size > 25
    end
    out.puts
    out.puts "Full report (JSON, Markdown, XLSX, CSV) is in the **axcess-accessibility-report** artifact."
    out.puts
  end
end

exit(failed ? 1 : 0)
