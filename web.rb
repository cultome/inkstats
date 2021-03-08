#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'inkstats'

class InkStat < Sinatra::Base
  get '/extract' do
    cookie = params.fetch('cookie', 'ebb3e0c264fd267aeaa0c6585089216e19e7f01f')

    storage = Inkstats::Storage.new
    parser = Inkstats::Parser.new
    extractor = Inkstats::Extractor.new cookie

    data = extractor.fetch_battles
    battles = parser.parse data
    inserted = storage.save battles

    { count: inserted }.to_json
  end

  get '/init' do
    { count: 50 }.to_json
  end
end
