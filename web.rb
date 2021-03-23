#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'inkstats'

class InkStat < Sinatra::Base
  set :default_content_type, 'application/json'

  get '/extract' do
    cookie = params.fetch('cookie', '6de06a709b77c4416ff8a739c4cac938ac080bb0')

    data = extractor(cookie).fetch_battles
    battles = parser.parse data
    inserted = storage.save battles

    { inserted: inserted }.to_json
  rescue Exception => error
    puts "[-] Error: #{error.message}:\n#{error.backtrace.join("\n  ")}"
    halt 500, { error: error.message }.to_json
  end

  get '/init' do
    storage.create_schema!

    { message: 'schema created' }.to_json
  end

  get '/version' do
    { version: '1.0.0' }.to_json
  end

  get '/drop' do
    storage.drop_schema!

    { message: 'schema created' }.to_json
  end

  def storage
    Inkstats::Storage.new
  end

  def parser
    Inkstats::Parser.new
  end

  def extractor(cookie)
    Inkstats::Extractor.new cookie
  end
end
