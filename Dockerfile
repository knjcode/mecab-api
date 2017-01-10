FROM ruby:2.4.0

MAINTAINER knjcode

RUN apt-get update \
    && apt-get install -y --force-yes mecab libmecab-dev mecab-ipadic-utf8 sudo unzip curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git /root/mecab-ipadic-neologd \
    && cd /root/mecab-ipadic-neologd \
    && ./bin/install-mecab-ipadic-neologd -n -y --forceyes \
    && cd /root \
    && rm -rf mecab-ipadic-neologd

# RUN git clone -b dockerizing https://github.com/knjcode/mecab-api /root/sinatra \
#     && cd /root/sinatra \
#     && bundle install \
#     && gem install foreman
WORKDIR /root/sinatra
COPY . .
RUN bundle install && gem install foreman

EXPOSE 9999
ENV PORT 9999
ENV MECAB_IPADIC_NEOLOGD_DICDIR /usr/lib/mecab/dic/mecab-ipadic-neologd

CMD ["foreman","start","-d","/root/sinatra"]
