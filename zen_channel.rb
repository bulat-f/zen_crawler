# frozen_string_literal: true

require 'uri'
require 'rest-client'
require 'json'

INITIAL_MORE_URL_BASE = 'https://zen.yandex.ru/api/v3/launcher/more?channel_id='

# ZenChannel
class ZenChannel
  attr_reader :items
  attr_accessor :channel_id

  def initialize(channel_id)
    @channel_id = channel_id
    @next_more_url = [INITIAL_MORE_URL_BASE, channel_id].join
    @items = []
  end

  def fetch_next_page!
    return nil unless @next_more_url

    response = JSON.parse RestClient.get(@next_more_url)

    return @next_more_url = nil if response['message'] == 'no docs'

    @items += response['items'].map { |item| item['link'] }
    @next_more_url = response['more']['link']
  rescue RestClient::Exception
    @next_more_url = nil
  end

  def fetch_all!
    fetch_next_page! until done?
  end

  def done?
    @next_more_url.nil?
  end
end
