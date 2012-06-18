# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'matrix'

module CIKRF

  def self.process_dir( path, output )
    Dir.chdir(path)
    File.open(output, 'w') do |f|
      f <<
        Dir.entries('.')
          .select{ |fname| fname[(-4)..(-1)] == 'html' }
          .map{ |p| self.parse_page(File.expand_path(p)) }
          .flatten(1)
          .map{|a| a.join(',')}
          .join("\n")
    end
  end

  def self.parse_page( html_file )
    page = Nokogiri::HTML(File.open(html_file))
             .xpath("//div[@style='width:100%; bgcolor:white;overflow:scroll']//td")
             .map(&:content)

    uik_ids = page.select{ |l| l.strip[0] == "У" }
                  .map { |node| node.strip.split("№").last.to_i }

    warn "Processing file: #{File.basename(html_file)} \t" +
         "UIK count: #{uik_ids.count}"

    shift = (13 * uik_ids.count) + 2

    votes =
      page[shift..(-1)].each_slice(uik_ids.size).map do |a|
        a.map { |str| str.strip.split("\n").first.to_i }
      end

    Matrix.rows(votes.unshift(uik_ids)).transpose.to_a
  end
end
