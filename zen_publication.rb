# frozen_string_literal: true

require 'nokogiri'
require 'uri'
require 'rest-client'
require 'json'

STATS_LINK_BASE = 'https://zen.yandex.ru/media-api/publication-view-stat?publicationId='

DESCRIPTION_MAX_LEN = 256
SENTENCE_SEPARATOR = /([\.\?\!])/.freeze

# ZenPublicatiob
class ZenPublication
  attr_accessor :title, :cover, :body, :link, :published_at, :publication_id,
                :views, :views_till_end, :sum_view_time_sec, :comments, :tags,
                :slug, :description

  def initialize(document)
    @document = Nokogiri::HTML(document)
    parse!
  end

  def to_s
    "#<ZenPublication title=\"#{title}\" published_at=\"#{published_at}\">"
  end

  # notice! some hash keys don't match attributes
  def stats_to_hash
    {
      views_count: views,
      views_till_end_count: views_till_end,
      sum_view_time_sec: sum_view_time_sec,
      comments_count: comments
    }
  end

  def script_tag_data_to_hash
    {
      slug: slug
    }
  end

  def to_hash
    {
      title: title,
      cover: cover,
      body: body,
      description: description,
      lang: lang,
      link: link,
      published_at: published_at
    }.merge stats_to_hash, script_tag_data_to_hash
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
    parse_script_tag!
    fetch_stats!
  end

  def parse_meta!
    @link = @document.css('link[rel="canonical"]').attr('href')
    @publication_id = URI(@link).path.split('-').last
    @published_at = @document.css('meta[itemprop="datePublished"]').attr('content')
  end

  def parse_title!
    @title = @document.css('.article__title').text.strip
  end

  def parse_body!
    body_blocks = @document.css('.article-render__block').map do |block|
      block.text.strip
    end
    body_blocks.filter! { |block| !block.nil? && !block.empty? }

    @body = body_blocks.join("\n")
    build_description! body_blocks.first if body_blocks.first
  end

  def parse_images!
    image_nodes = @document.css('.article-image__image')
    @images = image_nodes.map { |img| img.attr('src') }
    @cover = !@images.empty? && @images.first
  end

  def parse_script_tag!
    array_of_slug_parts = URI(@link).path.split('/').last.split('-')
    array_of_slug_parts.pop
    @slug = array_of_slug_parts.join('-')
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

  def build_description!(paragraph)
    if paragraph.length < DESCRIPTION_MAX_LEN
      @description = paragraph
    else
      @description = ''
      sentences = paragraph.split SENTENCE_SEPARATOR
      sentences << '.' if sentences.length.odd?
      cursor = 0
      while @description.length < DESCRIPTION_MAX_LEN / 2
        @description += sentences[cursor] + sentences[cursor + 1]
        cursor += 2
        break if cursor >= sentences.length
      end
    end
  end
end
