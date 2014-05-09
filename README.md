# Run the app

    bundle install
    bundle exec rackup

# Releasing

The site is hosted on Heroku. Once you have release karma, add a `heroku` remote pointing to `git@heroku.com:kickstartacademy.git` and you should be able to `git push heroku master`.

# Flushing the cache

Sometimes the blog gets stuck on the 'loading' page as the cache has saved the 'loading' version of the page.

In order to flush the page cache head to this link (when logged in to heroku):

https://addons-sso.heroku.com/apps/kickstartacademy/addons/memcachier:dev

And click the red 'flush' button.
