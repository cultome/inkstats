class Inkstats::Extractor
  attr_reader :cookie

  def initialize(cookie)
    @cookie = cookie
  end

  def fetch_battles
    headers = {
      'Host' => 'app.splatoon2.nintendo.net',
      'x-unique-id' => '32449507786579989234' ,
      'x-requested-with' => 'XMLHttpRequest',
      'x-timezone-offset' => '360',
      'User-Agent' => 'Mozilla/5.0 (Linux; Android 7.1.2; Pixel Build/NJH47D; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/59.0.3071.125 Mobile Safari/537.36',
      'Accept' => '*/*',
      'Referer' => 'https://app.splatoon2.nintendo.net/home',
      'Accept-Encoding' => 'gzip, deflate',
      'Accept-Language' => 'en-US',
      'Cookie' => "iksm_session=#{cookie}",
    }

    url = "https://app.splatoon2.nintendo.net/api/results"
    response = Faraday.get(url, {}, headers)

    raise 'Invalid authorization' if response.status == 403

    body = Zlib::GzipReader.new(StringIO.new(response.body)).read

    JSON.parse(body)['results']
  end
end
