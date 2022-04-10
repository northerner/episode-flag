#! /usr/bin/env ruby

require 'fileutils'
require 'digest'
require 'nokogiri'
require 'tty-progressbar'
require 'tty-prompt'
require 'pastel'

require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'async/http/internet'

FEEDS_DIR = "feeds"
MAX_FEEDS = 500
ASYNC_PROCESSES = 30
OPML_FILENAME = "podcasts_opml.xml"

begin
  opml = File.open("podcasts_opml.xml") { |f| Nokogiri::XML(f) }
rescue
  puts "Missing or invalid OPML file."
  puts "Please add your OPML file, renamed to \"#{OPML_FILENAME}\", to this directory."
  exit
end

prompt = TTY::Prompt.new

if prompt.yes?("Clear feeds cache? (Default: no)", default: false)
  FileUtils.rm(Dir.glob("#{FEEDS_DIR}/*"))
end

term = prompt.ask("Enter a search term: ")
rule = Regexp.new(term, Regexp::IGNORECASE)

cutoff_days = prompt.select("How far back should we search?") do |menu|
  menu.choice "1 week", 7
  menu.choice "2 weeks", 14 
  menu.choice "1 month", 31
  menu.choice "As far back as possible", 10_000
end

opml = File.open("podcasts_opml.xml") { |f| Nokogiri::XML(f) }
feeds = opml.xpath('//outline/outline', 'type' => 'rss')
matching_episodes = []
problem_feeds = []

Async do |task|
  barrier = Async::Barrier.new
	semaphore = Async::Semaphore.new(ASYNC_PROCESSES, parent: barrier)
  net = Async::HTTP::Internet.new
  feeds_to_process = ([feeds.count, MAX_FEEDS].min)
  bar = TTY::ProgressBar.new("processing [:bar] :current/:total", total: feeds_to_process)

  feeds.first(feeds_to_process).each do |feed|
    semaphore.async do
      feed_name = feed["text"]
      file_name = "#{FEEDS_DIR}/#{Digest::MD5.hexdigest(feed["xmlUrl"])}"

      unless File.exist?(file_name)
        begin
          task.with_timeout(2) do
            File.write(file_name, net.get(feed["xmlUrl"]).read)
          end
        rescue
          problem_feeds << feed_name
          bar.advance
          semaphore.release
          next
        end
      end

      parsed_feed = File.open(file_name) { |f| Nokogiri::XML(f) }
      latest_episodes = parsed_feed.xpath('//channel/item')

      Async do
        latest_episodes.each do |episode|
          date = DateTime.parse(episode.xpath('./pubDate').text)
          break if date < (DateTime.now - cutoff_days)

          title = episode.xpath('./title').text
          desc = episode.xpath('./description').text
          url = episode.xpath('./enclosure/@url').text

          if (desc.match(rule) || title.match(rule))
            matching_episodes << [feed_name, title, date, url]
          end
        end
      end

      bar.advance
    end
  end

  barrier.wait
ensure
  net&.close
end

pastel = Pastel.new

puts
puts pastel.yellow("#{matching_episodes.count} episodes found matching \"#{term}\"")
puts

matching_episodes.each do |ep|
  puts pastel.white.on_green.bold(ep[0]) + " - " + pastel.bold(ep[1])
  puts "Date: #{ep[2].strftime("%B %d, %Y")}"
  puts "URL: #{pastel.blue ep[3]}"
  puts
end

if problem_feeds.any?
  puts "Unable to download:"
  problem_feeds.each do |feed|
    puts "- #{feed}"
  end
end
