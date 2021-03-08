$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require './web'

run InkStat.new
