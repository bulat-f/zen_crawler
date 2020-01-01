# frozen_string_literal: true

require 'rest-client'
require 'json'
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
parsed_data.reverse!
parsed_data.uniq! { |publication| publication[:slug] }

output = File.open('result.json', 'w')
output.write(JSON.pretty_generate(parsed_data))
output.close

ratio_of_tt = tt_count.to_f / parsed_data.length * 100

puts
puts
puts "#{parsed_data.length} articles are parsed"
puts "#{tt_count} (#{ratio_of_tt.round}%) of them are tatar"
