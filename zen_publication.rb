# frozen_string_literal: true

require 'nokogiri'
require 'uri'
require 'json'

STATS_LINK_BASE = 'https://zen.yandex.ru/media-api/publication-view-stat?publicationId='

# ZenPublicatiob
class ZenPublication
  attr_accessor :title, :cover, :body, :link, :published_at, :publication_id,
                :views, :views_till_end, :sum_view_time_sec, :comments

  def initialize(document)
    @document = Nokogiri::HTML(document)
    parse!
  end

  def to_s
    "#<ZenPublication title=\"#{title}\" published_at=\"#{published_at}\">"
  end

  def to_hash
    {
      title: title,
      cover: cover,
      body: body,
      lang: lang,
      link: link,
      published_at: published_at,
      views: views,
      views_till_end: views_till_end,
      sum_view_time_sec: sum_view_time_sec,
      comments: comments
    }
  end

  def tt?
    lang == 'tt'
  end

  alias tatar? tt?

  protected

  def parse!
    # order matters
    parse_meta!
    parse_title!
    parse_body!
    parse_images!
    fetch_stats!
  end

  def parse_meta!
    @link = @document.css('link[rel="canonical"]').attr('href')
    @publication_id = URI(@link).path.split('-').last
    @published_at = @document.css('meta[itemprop="datePublished"]').attr('content')
  end

  def parse_title!
    @title = @document.css('.article__title').text
  end

  def parse_body!
    body_blocks = @document.css('.article-render__block').map do |block|
      block.text.strip
    end

    @body = body_blocks.join("\n")
  end

  def parse_images!
    @images = @document.css('.article-image__image').map { |img| img.attr('src') }
    @cover = !@images.empty? && @images.first
  end

  def fetch_stats!
    stats = JSON.parse RestClient.get([STATS_LINK_BASE, @publication_id].join)
    @views = stats['views']
    @views_till_end = stats['viewsTillEnd']
    @sum_view_time_sec = stats['sumViewTimeSec']
    @comments = stats['comments']
  end

  def lang
    @lang ||= body.include?('ә') ? 'tt' : 'ru'
  end
end
