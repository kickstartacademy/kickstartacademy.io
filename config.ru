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

before do
  @draft = params.fetch("draft") { false }
end

helpers do
  def view_drafts?
    @draft
  end

  def draft_only
    return unless view_drafts?
    yield if block_given?
  end

  def active(page)
  end

  def tweets
    return [] unless ENV['RACK_ENV'] == 'production'
    Twitter.user_timeline('kickstartac', count: 3) rescue []
  end

  def markup_tweet(raw)
    raw.
      gsub(/(https?[^ ]+)/, %Q{<a target="_blank" href="\\1">\\1</a>}).
      gsub(/@(\w+)/, %Q{<a target="_blank" href="http://twitter.com/\\1">@\\1</a>}).
      gsub(/#(\w+)/, %Q{<a target="_blank" href="http://twitter.com/search?q=%23\\1">#\\1</a>})
  end

  def blog_articles
    all_articles[0..15]
  end

  def article
  end

  def all_articles
    settings.blog.articles.sort do |a,b|
      b.published <=> a.published
    end
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

  def upcoming_events(type)
    events(type).reject { |e| e.start_date < Date.today }.sort_by(&:start_date)
  end

  def upcoming_event(type)
    upcoming_events(type).first
  end

  def all_events
    valtech = Venue.new('Valtech', '103 Rue de Grenelle, 75007, Paris, France', 48.856993,2.319338)
    ustwo   = Venue.new('usTwo', '62 Shoreditch High Street, London, E1 6JJ, United Kingdom', 51.5228274,-0.0778368)

    seb     = Coach.new( 'Seb Rose',          'seb',        '/images/seb-sm-bw.png' )
    rob     = Coach.new( 'Rob Chatley',       'rob',        '/images/rob.png'       )
    matt    = Coach.new( 'Matt Wynne',        'matt',       '/images/matt.png'      )
    steve   = Coach.new( 'Steve Tooke',       'tooky',      '/images/tooky.jpg'     )
    aslak   = Coach.new( 'Aslak Hellesøy',    'aslak',      '/images/aslak.jpg'     )
    julien  = Coach.new( 'Julien Biezemans',  'julien',     '/images/julien.png'    )
    sandi   = Coach.new( 'Sandi Metz',        'sandimetz',  '/images/sandi.jpg'     )
    liz     = Coach.new( 'Liz Keogh',         'liz',        '/images/liz.jpg'       )

    [
      Event.new(
        :bdd,
        'Atlanta, GA',
        Time.parse('5 Nov 2014'),
        Time.parse('7 Nov 2014'),
        Tito.new('bdd-kickstart-atlanta-nov-2014'),
        nil,
        [aslak, julien],
        %{Get a headstart with Behaviour-Driven Development, the collaborative process that's changing the face of software development.}
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
                'http://blog.mattwynne.net/tag/agile/atom',
                'http://claysnow.co.uk/?tag=bdd&feed=rss2',
                'http://chatley.com/atom.xml',
                'http://tooky.co.uk/feed.xml',
                'https://cucumber.pro/feed.xml',
                'http://www.sandimetz.com/atom.xml'
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
  courses/practical-object-oriented-design
  blog
  blog/archive
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

# draft pages
#%i(
#).each do |page|
  #path = "/#{page}"
  #get(path) do
    #return 404 unless view_drafts?
    #slim page
  #end
#end

get('/blog/:page_slug') { |page_slug|
  article = all_articles.detect { |a| a.page_slug == page_slug }
  slim :"blog/article", :locals => { :article => article }
}

get('/dates/:event_id') do |event_id|
  event = all_events.detect { |e| e.id == event_id }
  slim :"dates/course", :locals => { :event => event }
end

get('/maps.js') do
  content_type 'text/javascript'
  erb :'maps.js', layout: false
end

run Sinatra::Application
