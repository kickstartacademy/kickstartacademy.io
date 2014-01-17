require 'bundler/setup'
require 'sinatra'
require 'twitter'
require 'feedzirra'
require 'memcachier'
require 'dalli'
require 'rack-cache'
require 'yaml'
require 'slim'

require File.dirname(__FILE__) + '/lib/event'
require File.dirname(__FILE__) + '/lib/blog'

# Defined in ENV on Heroku. To try locally, start memcached and uncomment:
# ENV["MEMCACHE_SERVERS"] = "localhost"
if memcache_servers = ENV["MEMCACHE_SERVERS"]
  use Rack::Cache,
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"

  # Flush the cache
  Dalli::Client.new.flush
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
    settings.blog.articles.sort do |a,b|
      b.published <=> a.published
    end[0..15]
  end

  def popular_posts
    settings.blog.popular_articles.sort do |a,b|
      b.published <=> a.published
    end[0..15]
  end

  def blog_loading?
    settings.blog.refreshing?
  end

  def friendly_date(date)
    date.strftime("%a %-d %b %Y %H:%M")
  end

  def course_date(date)
    date.strftime("%-d %B %Y")
  end

  def course_date_range(dates)
    if (spans_month_boundary(dates))
      dates.first.strftime("%-d %B") + '-' + dates.last.strftime("%-d %B %Y")
    else
      dates.first.strftime("%-d") + '-' + dates.last.strftime("%-d %B %Y")
    end
  end

  def spans_month_boundary(daterange)
    daterange.first.month != daterange.last.month
  end

  def slugify(id)
    id.gsub(/\W/, '-')
  end

  def events(type)
    all_events.select { |e| e.type == type }
  end

  def upcoming_event(type)
    events(type).reject { |e| e.start_date < Date.today }.sort_by(&:start_date).first
  end

  def all_events
    #unboxed = Venue.new('Unboxed consulting', '17 Blossom Street, London, E1 6PL, United Kingdom', 51.521118, -0.077833)
    seb = Coach.new('Seb Rose', 'seb', '/images/seb-sm-bw.png')
    rob = Coach.new('Rob Chatley', 'rob', '/images/rob.png')
    [
      Event.new(
        :cd,
        'Paris',
        Time.parse('25 Mar 2014'),
        Time.parse('26 Mar 2014'),
        Tito.new('kickstart-cd-paris-2014'),
        nil,
        [rob, seb],
        %{Optimise the pipeline from a developer's fingers to your users' desktop.}
      ),
    ]
  end
end

set :static_cache_control, [:public, max_age: 1800]


BLOG_URLS = if ENV['BLOG_DEV']
              [
                'http://chrismdp.com/tag/bdd/atom.xml',
              ]
            else
              [
                'http://chrismdp.com/tag/cucumber/atom.xml',
                'http://chrismdp.com/tag/bddkickstart/atom.xml',
                'http://chrismdp.com/tag/bdd/atom.xml',
                'http://blog.mattwynne.net/tag/cucumber/atom',
                'http://blog.mattwynne.net/tag/bdd/atom',
                'http://claysnow.co.uk/?tag=bdd&feed=rss2',
                'http://chatley.com/atom.xml',
                'http://tooky.co.uk/rss/',
              ]
            end
set :blog, Blog.new(BLOG_URLS).refresh

before do
  cache_control :public, max_age: 1800  # 30 mins
end

get('/details')           { redirect '/bdd-details' }
get('/bdd-details')       { redirect '/courses/bdd-kickstart' }
get('/in-house')          { redirect '/in-house-courses' }
get('/in-house-training') { redirect '/in-house-courses' }
get('/about')             { redirect '/team' }

get("/")        { slim :index }

%i(
  courses/bdd-kickstart
  courses/continuous-delivery-kickstart
  blog
  coaching
  dates
  team
  courses
  thanks
  in-house-courses
).each do |page|
  path = "/#{page}"
  get(path) { slim page }
end

get('/maps.js') do
  content_type 'text/javascript'
  erb :'maps.js', layout: false
end

run Sinatra::Application
