# frozen_string_literal: true

require 'socket'
require 'set'
require 'logger'
require_relative 'peer'
require_relative 'peer_serializer'
require_relative 'request_type'
require_relative 'util'
require_relative 'listener'

module P2PChat
  class Server
    attr_reader :port, :flags, :ip_address, :message_len, :socket, :listener

    def initialize(port:, flags:, message_len:, logger: Logger.new($stdout))
      @peers = Set[]
      @logger = logger
      @flags = flags
      @message_len = message_len

      @socket = UDPSocket.new
      @ip_address = Util.private_ipv4_address
      @port = port
      @socket.bind @ip_address, @port

      @listener = Listener.new(socket: @socket, message_len:)
      @listener.on RequestType::CONNECT, &method(:on_connect)
      @listener.on RequestType::DISCONNECT, &method(:on_disconnect)
      @listener.on RequestType::KEEP_ALIVE, &method(:on_keep_alive)
    end

    def start
      @logger.info "Server listening on #{@ip_addr}:#{@port}"
      @listener.start
    end

    def stop
      @listener.stop
    end

    def on_connect(message, public_ip, public_port)
      private_ip, private_port = message.chomp.split(':')
      private_port = private_port.to_i

      peer = Peer.new(public_ip:, public_port:,
                      private_ip:, private_port:)
      reply_message = @peers.map { PeerSerializer.serialize _1 }.join("\n")
      @peers << peer

      @socket.send reply_message, @flags, public_ip, public_port

      @logger.info "CONNECT #{PeerSerializer.serialize peer}"
    end

    def on_disconnect(_message, public_ip, public_port)
      @peers.reject! do |peer|
        [public_ip, public_port] == [peer.public_ip, peer.public_port]
      end
      @logger.info "DISCONNECT #{public_ip}:#{public_port}"
    end

    def on_keep_alive(_message, public_ip, public_port)
      @logger.info "KEEP_ALIVE #{public_ip}:#{public_port}"
    end
  end
end
