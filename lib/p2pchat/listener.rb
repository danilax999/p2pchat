# frozen_string_literal: true

require 'socket'
require 'set'
require_relative 'peer'
require_relative 'peer_serializer'
require_relative 'request_type'
require_relative 'util'

module P2PChat
  class Listener
    attr_reader :socket,
                :message_len,
                :handlers

    def initialize(socket:, message_len:)
      @socket = socket
      @message_len = message_len
      @handlers = []
    end

    def recieve
      IO.select [@socket] # Non-blocking recvfrom
      message, addr_info = @socket.recvfrom @message_len
      request_type, message = message.split(' ', 2)
      request_type = request_type.to_i
      public_ip, public_port = addr_info.values_at(3, 1)

      @handlers[request_type]&.each do |proc|
        proc.call(message, public_ip, public_port)
      end
    end

    def on(request_type, &block)
      (@handlers[request_type] ||= []) << block
    end

    def start
      loop { recieve }
      stop
    end

    def stop
      @socket.close
    end
  end
end
