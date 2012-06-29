# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'matrix'

module CIKRF

  # Pulic: Extract data from all html pages from a given folder.
  #
  # path - The String with absolute path to directory with html files
  # output - The String with absolute path to resulting file
  # supp_columns - The Integer statiting by how much the number of lines
  #   in the protocol exceeds the default.
  #
  # Returns the String "Complete!"
  def self.process_dir( path, output, supp_columns=0 )
    Dir.chdir(path)
    File.open(output, 'w') do |f|
      f <<
        Dir.entries('.')
          .select{ |fname| fname[(-4)..(-1)] == 'html' }
          .tap{ |files| warn "Found #{files.size} files" }
          .map{ |p| self.parse_page(File.expand_path(p), supp_columns) }
          .flatten(1)
          .map{|a| a.join(',')}
          .join("\n")
    end
    warn 'Complete!'
  end

  def self.parse_page( html_file, supp_columns )

    table = Nokogiri::HTML(File.open(html_file))
             .xpath("//div[@style='width:100%; bgcolor:white;overflow:scroll']//td")
             .map(&:content)

    uik_ids = table.select{ |l| l.strip[0] == "У" }
                   .map { |node| node.strip.split("№").last.to_i }

    warn "Processing: #{File.basename(html_file)} \t" +
         "UIK count: #{uik_ids.count}"

    ballots_interval =
      (uik_ids.count)..(uik_ids.count*(12+supp_columns))

    ballots =
      table[ballots_interval]
        .each_slice(uik_ids.size)
        .map { |a| a.map { |str| str.strip.to_i } }[0..(-2)]

    votes_interval =
      (((12+supp_columns)*uik_ids.count)+2)..(-1)

    votes =
      table[votes_interval].each_slice(uik_ids.size).map do |a|
        a.map { |str| str.strip.split("\n").first.to_i }
      end

    Matrix.rows((ballots + votes).unshift(uik_ids)).transpose.to_a
  end
end
