require 'bundler/setup'
require 'sinatra'
require 'twitter'
require 'feedzirra'

require 'dalli'
require 'rack-cache'

# Defined in ENV on Heroku. To try locally, start memcached and uncomment:
# ENV["MEMCACHE_SERVERS"] = "localhost"
if memcache_servers = ENV["MEMCACHE_SERVERS"]
  use Rack::Cache,
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"
end

Twitter.configure do |config|
  config.consumer_key = '5sD8eQtceH3dFX53KAmBrg'
  config.consumer_secret = 'Bs4maTs0neLCs1Hm7LnjooOmkQITLLDahclCzQINW74'
  config.oauth_token = '860940638-JdRZgiJ878yOdLR757akKn8FfmsCVW5l73buMCeR'
  config.oauth_token_secret = 'b6nHS25AmaPjVInwfF1DjpoNQo0ufwtkpny9lK00'
end

helpers do
  def active(page)
  end

  def tweets
    return [] unless ENV['RACK_ENV'] == 'production'
    Twitter.user_timeline('bddkickstart', count: 3) rescue []
  end

  def markup_tweet(raw)
    raw.
      gsub(/(https?[^ ]+)/, %Q{<a target="_blank" href="\\1">\\1</a>}).
      gsub(/@(\w+)/, %Q{<a target="_blank" href="http://twitter.com/\\1">@\\1</a>}).
      gsub(/#(\w+)/, %Q{<a target="_blank" href="http://twitter.com/search?q=%23\\1">#\\1</a>})
  end

  def blog_articles
    blog_urls.map do |url|
      feed = Feedzirra::Feed.fetch_and_parse(url).entries
    end.flatten.uniq(&:id).sort do |a,b|
      b.published <=> a.published
    end
  end

  def blog_urls
    return [] unless ENV['RACK_ENV'] == 'production'
    [
      'http://chrismdp.com/tag/cucumber/atom.xml',
      'http://chrismdp.com/tag/bddkickstart/atom.xml',
      'http://chrismdp.com/tag/bdd/atom.xml',
      'http://blog.mattwynne.net/tag/cucumber/atom',
      'http://blog.mattwynne.net/tag/bdd/atom',
    ]
  end

  def friendly_date(date)
    date.strftime("%a %d %b %Y %H:%M")
  end

  def slugify(id)
    id.gsub(/\W/, '-')
  end

  Event = Struct.new(:title, :date, :eventbrite_id, :venue) do
    def id
      title.downcase
    end

    def tickets?
      !!eventbrite_id
    end

    def venue?
      !!venue
    end

    def with_venue
      yield venue if venue?
    end
  end

  Venue = Struct.new(:name, :address, :lat, :lng)

  def events
    [
      Event.new('Brussels',  '6-8 Feb 2013', 5029886526, 
        Venue.new('BetaGroup Coworking', '4 rue des Pères Blancs, 1040 Etterbeek, Brussels, Belgium', 50.8267944, 4.4002839)),
      Event.new('Edinburgh', '11-13 March 2012'),
      Event.new('Barcelona', '11-13 Sept 2013'),
    ]
  end
end

set :static_cache_control, [:public, max_age: 1800]

before do
  cache_control :public, max_age: 1800  # 30 mins
end

get '/' do
  erb :index
end

[:about, :details, :dates, :blog, :thanks].each do |page|
  get "/#{page}" do
    erb page
  end
end

run Sinatra::Application
