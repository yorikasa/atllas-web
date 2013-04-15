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

get '/:cat' do
    if not %w(society politic sport entertainment tech fun).include?(params[:cat])
        redirect not_found
    end
    
    @categories = {society: "社会",
        politic: "政治経済",
        sport: "スポーツ",
        entertainment: "エンタメ",
        tech: "テクノロジー",
        fun: "2ch・おもしろ"}
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
    erb :category, :locals => {cat_en: params[:cat], cat_ja: @categories[params[:cat].to_sym]}
end

get '/page/:url' do
    target = Url.where(url: CGI.unescape(CGI.unescape(params[:url]))).first
    redirect not_found if not target
    @related = []
    @nears = []
    if ttime = target[:created_at]
        Url.where(created_at: (ttime-3600*6..ttime+3600*6)).desc(:count_all_twitter).limit(30).each do |url|
            next if target.id == url.id
            next if url.url.include?('www.nicovideo.jp')
            @nears << url
        end
    end
    if target[:related]
        target.related.each do |rid|
            @related << Url.where(id: rid).first
        end
    end
    erb :individual, :locals => {url: target}
end


get '/*' do
    redirect not_found
end


not_found do
    @no_ad = true
    erb :not_found
end