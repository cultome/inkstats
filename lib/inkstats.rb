# frozen_string_literal: true

require 'faraday'
require 'json'
require 'pg'

require_relative "inkstats/version"
require_relative "inkstats/extractor"
require_relative "inkstats/parser"
require_relative "inkstats/storage"
