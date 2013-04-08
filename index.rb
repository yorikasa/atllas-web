#!/usr/bin/env ruby
# coding: utf-8

require 'sinatra'
require 'mongoid'
require 'benchmark'

require './configure'
require './misc'

class Url
    include Mongoid::Document
    field :url, type: String
    field :image_url, type: String
    field :title, type: String
    field :body, type: String
    field :category, type: String

    # Twitterでの言及数を数える
    field :timestamps_twitter, type: Array
    field :counting_twitter, type: Integer
    field :counted_twitter, type: Integer
    field :count_all_twitter, type: Integer
    
    field :count_all_facebook, type: Integer

    # はてなブックマークの数を数える
    field :count_recent_hatena, type: Integer
    field :count_all_hatena, type: Integer
end

get '/' do
    @video = []
    @app = []
    @market = []

    @urls = []
    @recents = []

    Url.limit(50).desc(:counting_twitter).each do |url|
        if /youtube\.com/ =~ url.url
            @video << url
            next
        end
        if /play\.google\.com|itunes\.apple\.com/ =~ url.url
            # @app << url
            next
        end
        if /amazon\.co\.jp/ =~ url.url
            @market << url
            next
        end
        next if url.url.include?("rakuten.co.jp")
        next if url.url.include? "www.nicovideo.jp"
        @recents << url if @recents.size < 15
    end

    Url.limit(100).desc(:counted_twitter).each do |url|
        if /youtube\.com/ =~ url.url
            @video << url
            next
        end
        if /play\.google\.com|itunes\.apple\.com/ =~ url.url
            # @app << url
            next
        end
        if /amazon\.co\.jp/ =~ url.url
            @market << url
            next
        end
        next if url.url.include?("rakuten.co.jp")
        next if url.url.include? "www.nicovideo.jp"

        if url.count_all_hatena
            next if url.count_all_hatena < 3
        else
            next
        end
        
        @urls << url if @urls.size < 30
    end
    erb :index
end

get '/:cat' do
    @urls = []
    @recents = []
    @video = []
    @app = []
    @market = []

    count = 0
    Url.where(category: params[:cat].capitalize).limit(100).desc(:counted_twitter).each do |url|
        if /youtube\.com|www\.nicovideo\.jp/ =~ url.url
            @video << url
            next
        end
        if /play\.google\.com|itunes\.apple\.com/ =~ url.url
            @app << url
            next
        end
        if /amazon\.co\.jp|rakuten\.co\.jp/ =~ url.url
            @market << url
            next
        end
        count += 1
        @urls << url if count < 30
    end

    count = 0
    Url.where(category: params[:cat].capitalize).limit(50).desc(:counting_twitter).each do |url|
        if /youtube\.com|www\.nicovideo\.jp/ =~ url.url
            @video << url
            next
        end
        if /play\.google\.com|itunes\.apple\.com/ =~ url.url
            @app << url
            next
        end
        if /amazon\.co\.jp|rakuten\.co\.jp/ =~ url.url
            @market << url
            next
        end
        count += 1
        @recents << url if count < 30
    end
    erb :category, :locals => {cat_name: params[:cat]}
end

get '/page/:id' do
    target = Url.where(id: params[:id]).first
    @related = []
    @nears = []
    if ttime = target[:created_at]
        Url.where(created_at: (ttime-3600*5..ttime+3600*5)).desc(:count_all_twitter).each do |url|
            next if target.id == url.id
            # next if not url[:counted_twitter]
            # next if not url[:count_all_hatena]
            next if (0 < url[:counting_twitter]) and (url[:counting_twitter] < 5)
            # next if url.count_all_twitter < 10
            # next if url.count_all_hatena < 5
            if sim(target.title, url.title) > 0.3
                @related << url
            else
                @nears << url
            end
        end
    end
    erb :individual, :locals => {url: target}
end
