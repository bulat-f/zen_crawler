require 'nokogiri'
require 'rest-client'
require 'json'
require 'uri'

input = File.open('index.html', 'r')
data = input.read
input.close

page = Nokogiri::HTML(data)
STATS_LINK_BASE = 'https://zen.yandex.ru/media-api/publication-view-stat?publicationId='

tt_count = 0

parsed_data = page.css('a.card-image-view__clickable').map do |link|
  article = Nokogiri::HTML(RestClient.get(link['href']))

  body = ''
  canonical = article.css('link[rel="canonical"]').attr('href')
  uri = URI(canonical)
  publication_id = uri.path.split('-').last

  puts RestClient.get([STATS_LINK_BASE, publication_id].join)

  article.css('.article-render__block').each do |block|
    body += block.text.strip + "\n"
  end

  lang = body.include?('ә') ? 'tt' : 'ru'

  tt_count += 1 if lang == 'tt'

  images = article.css('.article-image__image')

  print '.'

  {
    title: article.css('.article__title').text,
    lang: lang,
    link: canonical,
    cover: !images.empty? && images[0]['src'],
    published_at: article.css('meta[itemprop="datePublished"]').attr('content'),
    read_count: article.css('span.article-stat__count').text,
    likes: article.css('span.likes-count-minimal__count').text,
    body: body
  }
end

parsed_data.filter! { |article| !article[:title].empty? }
output = File.open('result.json', 'w')
output.write(parsed_data.to_json)
output.close

ratio_of_tt = tt_count.to_f / parsed_data.length * 100

puts
puts "#{parsed_data.length} articles are parsed"
puts "#{tt_count} (#{ratio_of_tt.round}%) of them are tatar"
