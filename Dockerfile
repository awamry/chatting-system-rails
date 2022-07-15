FROM ruby:3.1.2

RUN apt-get install -y default-libmysqlclient-dev

WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .

ENV RAILS_ENV production
EXPOSE 3000
