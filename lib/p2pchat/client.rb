# frozen_string_literal: true

require 'socket'
require 'set'
require 'readline'
require_relative 'peer'
require_relative 'peer_serializer'
require_relative 'request_type'
require_relative 'util'
require_relative 'listener'

module P2PChat
  class Client
    attr_reader :port,
                :server_ip,
                :server_port,
                :socket,
                :peers,
                :flags,
                :ip_address,
                :listener

    def initialize(port:, server_ip:, server_port:, message_len:,
                   keep_alive_sleep_duration:, flags:)
      @server_ip = server_ip
      @server_port = server_port
      @flags = flags
      @message_len = message_len
      @keep_alive_sleep_duration = keep_alive_sleep_duration
      @peers = Set[]
      @callbacks = {}

      @socket = UDPSocket.new
      @ip_address = Util.private_ipv4_address
      @port = port
      @socket.bind '0.0.0.0', @port

      @listener = Listener.new(socket: @socket, message_len:)
      @listener.on RequestType::CONNECT, &method(:on_connect)
      @listener.on RequestType::DISCONNECT, &method(:on_disconnect)
    end

    def connect
      out_message = "#{ip_address}:#{@port}"
      send2server out_message, request_type: RequestType::CONNECT
      in_message, addr_info = @socket.recvfrom(@message_len)
      @peers = in_message.lines
                         .map { PeerSerializer.deserialize _1 }
                         .reject { peer_is_me _1 }
      send2peers out_message, request_type: RequestType::CONNECT
      @callbacks[:connect]&.each(&:call)
    end

    def disconnect
      send2server request_type: RequestType::DISCONNECT
      send2peers request_type: RequestType::DISCONNECT
      @callbacks[:disconnect]&.each(&:call)
    end

    def start
      connect
      @listener.start
      stop
    end

    def stop
      disconnect
      @listener.stop
    end

    def send2server(message = '', request_type: RequestType::CONNECT)
      @socket.send "#{request_type} #{message}",
                   @flags,
                   @server_ip,
                   @server_port
    end

    def send2peers(message = '', request_type: RequestType::MESSAGE)
      @peers.each do |peer|
        @socket.send "#{request_type} #{message}",
                     @flags,
                     peer.private_ip,
                     peer.private_port

      rescue Errno::ENETUNREACH
        @socket.send message,
                     @flags,
                     peer.public_ip,
                     peer.public_port
      end
    end

    def on(hook, &block)
      (@callbacks[hook] ||= []) << block
    end

    private

    def on_connect(message, public_ip, public_port)
      private_ip, private_port = message.chomp.split(':')
      @peers << Peer.new(private_ip:,
                         private_port: private_port.to_i,
                         public_ip:,
                         public_port:)
    end

    def on_disconnect(_message, public_ip, public_port)
      @peers.reject! do |peer|
        [public_ip, public_port] == [peer.public_ip, peer.public_port]
      end
    end

    def peer_is_me(peer)
      [peer.private_ip, peer.private_port] == [ip_address, @port]
    end
  end
end
