require 'feedzirra'
class Blog
  def initialize(urls)
    @sources = urls.map { |url| Source.new(url) }
  end

  def articles
    sources.inject([]) do |articles, source|
      articles + source.articles
    end
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
          Timeout.timeout(10) do
            @status = :refreshing
            p "#{url}: Refreshing"
            Feedzirra::Feed.add_common_feed_entry_element('posterous:firstName', as: 'author')
            feed = Feedzirra::Feed.fetch_and_parse(url)
            @articles = feed.entries
            p "#{url}: Fetched #{@articles.count} articles"
          end
        rescue => e
          p "#{url}: #{e}"
        ensure
          p "#{url}: Going back to idle status"
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

end
