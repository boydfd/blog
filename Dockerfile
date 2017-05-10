FROM ruby:2.4.1
ENV blog /blog
WORKDIR ${blog}
RUN gem install rubygems-update && update_rubygems 
COPY ./Gemfile ${blog}/
RUN bundle install
COPY . ${blog}
CMD bundle exec jekyll serve -H 0.0.0.0 -P 8000

