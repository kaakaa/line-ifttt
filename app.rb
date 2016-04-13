# Mostly taken from http://qiita.com/masuidrive/items/1042d93740a7a72242a3
# And https://github.com/yuya-takeyama/line-echo

require 'sinatra/base'
require 'json'
require 'rest-client'

class App < Sinatra::Base
  SECRET_KEY = ENV['MAKER_SECRET_KEY'] # Maker channel's secret key
  EVENT_NAME_DEFAULT = ENV['MAKER_EVENT_NAME_DEFAULT'] # Maker channel's default event name
  
  post '/linebot/callback' do
    params = JSON.parse(request.body.read)
    
    RestClient.proxy = ENV['FIXIE_URL'] if ENV['FIXIE_URL']
    params['result'].each do |msg|
      event, message = msg['content']['text'].split(' ', 2)
      response = request_to_ifttt(event, message)
      
      request_to_line([msg['content']['from']], response)
    end

    "OK"
  end

  helpers do
    def request_to_ifttt(event = EVENT_NAME, message)
      # Maker channel's extra data
      request_content = {
        value1: message,
        value2: 'from',
        value3: 'Line Bot'
      }

      endpoint_uri = "https://maker.ifttt.com/trigger/#{event}/with/key/#{SECRET_KEY}"
      content_json = request_content.to_json
      
      response = RestClient.post(endpoint_uri, content_json, {
        'Content-Type' => 'application/json; charset=UTF-8',
        'Content-Length' => content_json.length
      })
    end

    def request_to_line(send_to, message)
      request_content = {
        to: send_to,
        toChannel: 1383378250, # Fixed  value
        eventType: "138311608800106203", # Fixed value
        content: { 
            "contentType": 1,  # Text type message
            "toType": 1,
            "text": message
        }
      }

      endpoint_uri = 'https://trialbot-api.line.me/v1/events'
      content_json = request_content.to_json

      RestClient.post(endpoint_uri, content_json, {
        'Content-Type' => 'application/json; charset=UTF-8',
        'X-Line-ChannelID' => ENV["LINE_CHANNEL_ID"],
        'X-Line-ChannelSecret' => ENV["LINE_CHANNEL_SECRET"],
        'X-Line-Trusted-User-With-ACL' => ENV["LINE_CHANNEL_MID"],
      })
    end  
  end
end
