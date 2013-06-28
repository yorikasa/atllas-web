#!/usr/bin/env ruby
# coding: utf-8

require 'sinatra'
require 'mongoid'
require 'benchmark'
require 'time'
require 'cgi'

require './configure'
require './misc'

class Url
    include Mongoid::Document
    field :url, type: String
    field :image_url, type: String
    field :title, type: String
    field :title_array, type: Array
    field :body, type: String
    field :category, type: String

    # Twitterでの言及数を数える
    field :tweets, type: Array
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

get '/about' do
    @no_ad = true
    erb :about
end

get '/*' do
    redirect not_found
end


not_found do
    @no_ad = true
    erb :not_found
end
