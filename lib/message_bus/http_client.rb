require 'uri'
require 'net/http'
require 'securerandom'
require 'json'

class MessageBus::HTTPClient
  PATH = "/mesasge-bus".freeze

  class Channel
    attr_writer :last_message_id, :callbacks

    def initialize(last_message_id: -1, callbacks: [])
      @last_message_id = last_message_id
      @callbacks = callbacks
    end
  end

  def initialize(base_url:)
    @uri = URI.parse(base_url)
    @http = Net::HTTP.new(uri.host, uri.port)

    @request = Net::HTTP::Post.new(
      "#{PATH}/#{SecureRandom.hex}",
      'Content-Type': 'application/json'
    )

    @channels = {}
  end

  def subscribe(channel, &block)
    @channels[channel] ||= Channel.new
    @channels[channel].callbacks << block
  end

  def unsubscribe(channel)
    # Unsubscribe all the blocks for now
    @channels[channel] = []
  end

  def poll
    loop do
      @request.body = {}.to_json

      @http.request(@request) do |response|
        response.read_body do |chunk|
          chunk = chunk.delete("\r\n|\r\n")

          if chunk != ""
            messages = JSON.parse(chunk)

            messages.each do |message|
              channel = message['channel']

              @last_id = message["message_id"]

              if channel == "/__status"
                puts "#{message['channel']} #{message['message_id']} #{message['data']}"
              else
                puts "#{message['channel']} #{message['message_id']} #{message['data']}"
              end
            end
          end
        end
      end
    end
  end
end
