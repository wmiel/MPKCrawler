require 'nokogiri'
require 'open-uri'
require 'uri'
require 'set'

LINK = Struct.new(:href, :text)

class Crawler
  attr_reader :page, :raw_html

  def initialize(url)
    @url = URI.parse(url)
    @raw_html = open(url).read
    @page = Nokogiri::HTML(@raw_html)
  end

  def links
    raw_links.compact
  end

  def same_domain_links
    links.select { |link| link.href.host == @url.host }
  end

  def frames
    frames = @page.css('frame').map do |iframe|
      routed_link(iframe['src'])
    end
    frames.compact
  end

  private

  def raw_links
    @page.css('a').map do |a|
      routed_uri = routed_link(a['href'])
      LINK.new(routed_uri, a.text) if routed_uri
    end
  end

  def routed_link(href)
    return nil if !href || anchor?(href)
    @url.merge(URI.parse(href))
  rescue Exception => ex
    p ex
    nil
  end

  def anchor?(href)
    href.start_with?('#')
  end
end