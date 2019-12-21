# frozen_string_literal: true

require 'nokogiri'
require 'rest-client'
require 'json'
require 'uri'
require_relative 'zen_publication'

input = File.open('index.html', 'r')
data = input.read
input.close

page = Nokogiri::HTML(data)

tt_count = 0

parsed_data = page.css('a.card-image-view__clickable').map do |link|
  publication = ZenPublication.new(RestClient.get(link['href']))
  print '.'
  tt_count += 1 if publication.tt?
  publication.to_hash
end

parsed_data.filter! { |article| !article[:title].empty? }
output = File.open('result.json', 'w')
output.write(parsed_data.to_json)
output.close

ratio_of_tt = tt_count.to_f / parsed_data.length * 100

puts
puts "#{parsed_data.length} articles are parsed"
puts "#{tt_count} (#{ratio_of_tt.round}%) of them are tatar"
