require 'feedzirra'
class Blog
  def initialize(urls)
    @sources = urls.map { |url| Source.new(url) }
  end

  def articles
    sources.inject([]) do |articles, source|
      articles + source.articles
    end.flatten.uniq(&:url)
  end

  def popular_articles
    urls = File.read(File.expand_path(__FILE__ + '/../../config/popular_articles')).lines.map(&:strip)
    urls.map do |url|
      if article = articles.find { |a| a.url =~ /#{url}/ }
        puts "popular articles: Found #{url}"
        article
      else
        puts "popular articles: Could not find #{url}"
        nil
      end
    end.compact
  end

  def refresh(options = {})
    sources.each &:refresh
    if options[:sync]
      while refreshing?
        sleep 0.1
      end
    end
    self
  end

  def refreshing?
    sources.any? { |s| s.refreshing? }
  end

  def inspect
    sources.map { |source| [source.url, source.status] }
  end

  private

  def sources
    @sources
  end

  class Source
    attr_reader :url, :status

    def initialize(url)
      @url = url
      @status = :idle
    end

    def refresh
      Thread.new do
        begin
          Timeout.timeout(20) do
            @status = :refreshing
            p "blog: #{url}: Refreshing"
            Feedzirra::Feed.add_common_feed_entry_element('posterous:firstName', as: 'author')
            feed = Feedzirra::Feed.fetch_and_parse(url)
            @articles = feed.entries.map { |e| Article.new(e) }
            p "blog: #{url}: Fetched #{@articles.count} articles"
          end
        rescue => e
          p "blog: #{url}: #{e}"
        ensure
          p "blog: #{url}: Going back to idle status"
          @status = :idle
        end
      end
    end

    def refreshing?
      @status == :refreshing
    end

    def articles
      @articles ||= []
    end
  end

  require 'delegate'
  class Article < SimpleDelegator
    def page_slug
      @page_slug ||= "#{published.strftime("%Y-%m-%d")}-#{title.downcase.gsub(/\W+/, '-')}"
    end
  end

end
