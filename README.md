[![Circle CI](https://circleci.com/gh/kickstartacademy/kickstartacademy.io.png?style=badge)](https://circleci.com/gh/kickstartacademy/kickstartacademy.io)

# Run the app

    bundle install
    bundle exec rackup
    bundle exec rackup

# Run the tests

    bundle exec rspec

# Releasing

The site is hosted on Heroku. Pushing a build to Github is enough to trigger deployment, which will happen if the tests all pass.

# Flushing the cache

Sometimes the blog gets stuck on the 'loading' page as the cache has saved the 'loading' version of the page.

In order to flush the page cache head to this link (when logged in to heroku):

https://addons-sso.heroku.com/apps/kickstartacademy/addons/memcachier:dev

And click the red 'flush' button.
