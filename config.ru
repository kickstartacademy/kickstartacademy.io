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
    Twitter.user_timeline('bddkickstart', count: 3) rescue []
  end

  def markup_tweet(raw)
    raw.
      gsub(/(https?[^ ]+)/, %Q{<a target="_blank" href="\\1">\\1</a>}).
      gsub(/@(\w+)/, %Q{<a target="_blank" href="http://twitter.com/\\1">@\\1</a>}).
      gsub(/#(\w+)/, %Q{<a target="_blank" href="http://twitter.com/search?q=%23\\1">#\\1</a>})
  end

  def blog_articles
    [
      'http://chrismdp.com/tag/cucumber/atom.xml',
      'http://chrismdp.com/tag/bddkickstart/atom.xml',
      'http://chrismdp.com/tag/bdd/atom.xml',
    ].map do |url|
      feed = Feedzirra::Feed.fetch_and_parse(url).entries
    end.flatten.uniq(&:id).sort do |a,b|
      b.published <=> a.published
    end
  end

  def friendly_date(date)
    date.strftime("%a %d %b %Y %H:%M")
  end
end

set :static_cache_control, [:public, max_age: 1800]

get '/' do
  cache_control :public, max_age: 1800  # 30 mins
  erb :index
end

[:about, :details, :dates, :blog].each do |page|
  get "/#{page}" do
    cache_control :public, max_age: 1800  # 30 mins
    erb page
  end
end

get '/thanks*' do
  cache_control :public, max_age: 1800  # 30 mins
  erb :thanks
end

run Sinatra::Application
