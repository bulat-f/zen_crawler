# frozen_string_literal: true

require 'nokogiri'
require 'rest-client'
require 'json'
require 'uri'
require_relative 'zen_channel'
require_relative 'zen_publication'

CHANNEL_ID = '5b81707d5d36b000af9e8529'

channel = ZenChannel.new(CHANNEL_ID)

puts 'Fetching channel publications list'
channel.fetch_all!
puts 'Publications list is fetched'

tt_count = 0

parsed_data = channel.items.map do |link|
  publication = ZenPublication.new RestClient.get(link)
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
puts

max_views = parsed_data.max { |a, b| a[:views] <=> b[:views] }
max_views_till_end = parsed_data.max do |a, b|
  a[:max_views_till_end] <=> b[:max_views_till_end]
end
most_readable = parsed_data.max do |a, b|
  a_ratio = a[:max_views_till_end].to_f / a[:views]
  b_ratio b[:max_views_till_end].to_f / b[:views]
  a_ratio <=> b_ratio
end

puts "Most viewed publication is #{max_views[:title]}"
puts "Most viewed till the end publication is #{max_views_till_end[:title]}"
puts "Most readable publication is #{most_readable[:title]}"
