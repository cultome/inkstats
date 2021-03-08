#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'inkstats'

class InkStat < Sinatra::Base
  default_content_type 'application/json'

  get '/extract' do
    cookie = params.fetch('cookie', 'ebb3e0c264fd267aeaa0c6585089216e19e7f01f')

    data = extractor(cookie).fetch_battles
    battles = parser.parse data
    inserted = storage.save battles

    { inserted: inserted }.to_json
  end

  get '/init' do
    storage.create_schema!

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
