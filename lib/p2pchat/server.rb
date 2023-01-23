# frozen_string_literal: true

require 'socket'
require 'set'
require 'logger'
require_relative 'peer'
require_relative 'peer_serializer'
require_relative 'request_type'
require_relative 'util'

module P2PChat
  class Server
    attr_reader :port, :message_len, :socket

    def initialize(port:, message_len:, logger: Logger.new($stdout))
      @port = port
      @message_len = message_len
      @socket = UDPSocket.new
      @ip_addr =  Util.private_ipv4_address
      @socket.bind @ip_addr, port
      @peers = Set.new
      @logger = logger
    end

    def listen
      @logger.info "Server listening on #{@ip_addr}:#{@port}"
      loop do
        message, addr_info = @socket.recvfrom @message_len
        type, message = message.split(' ', 2)
        type = type.to_i

        public_ip, public_port = addr_info.values_at(3, 1)

        case type
        when RequestType::KEEP_ALIVE
          @logger.info "KEEP_ALIVE: #{public_ip}:#{public_port}"

        when RequestType::CONNECT
          private_ip, private_port = message.chomp.split(':')

          peer = Peer.new(public_ip:, public_port:,
                          private_ip:, private_port:)
          reply_message = @peers.map { PeerSerializer.serialize _1 }.join("\n")
          @peers << peer
          # @socket.send reply_message, flags, public_ip, public_port
          send reply_message, to: peer

          @logger.info "CONNECT: #{peer}"

        when RequestType::DISCONNECT
          @peers.reject! do |peer|
            [public_ip, public_port] == [peer.public_ip, peer.public_port]
          end
          @logger.info "DISCONNECT: #{public_ip}:#{public_port}"
        end
        @logger.debug "Peers: #{@peers}"
      end
    rescue Interrupt
      socket.close
    end

    def flags = 0

    def send(message = '', to:)
      peer = to
      @socket.send message, flags, peer.public_ip, peer.public_port
    end
  end
end
