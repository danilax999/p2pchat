# frozen_string_literal: true

require 'socket'
require 'set'
require 'readline'
require_relative 'peer'
require_relative 'peer_serializer'
require_relative 'request_type'
require_relative 'util'

module P2PChat
  class Client
    attr_reader :port,
                :server_ip,
                :server_port,
                :socket,
                :peers

    def initialize(port:, server_ip:, server_port:, message_len:,
                   keep_alive_sleep_duration:)
      @port = port
      @server_ip = server_ip
      @server_port = server_port
      @message_len = message_len
      @keep_alive_sleep_duration = keep_alive_sleep_duration
      @socket = UDPSocket.new
      @socket.bind ip_address, port
      @peers = Set[]
    end

    def connect
      message = "#{ip_address}:#{@port}"
      send2server message, request_type: RequestType::CONNECT
      message_from_server, addr_info = @socket.recvfrom(@message_len)
      @peers = message_from_server.lines.map { PeerSerializer.deserialize _1 }
      send2peers message, request_type: RequestType::CONNECT
      @peers.reject { peer_is_me _1 }
            .each do |peer|
        puts "== Peer #{peer.public_ip}:#{peer.public_port} is connected =="
      end
    end

    def ip_address
      @ip_address ||= Util.private_ipv4_address
    end

    def flags = 0

    def keep_alive_loop
      loop do
        sleep @keep_alive_sleep_duration
        send2server request_type: RequestType::KEEP_ALIVE
      end
    end

    def recv_loop
      loop do
        IO.select [@socket]
        message, addr_info = @socket.recvfrom @message_len
        type, message = message.split(' ', 2)
        public_ip, public_port = addr_info.values_at(3, 1)
        addr = "#{public_ip}:#{public_port}"

        case type.to_i
        when RequestType::MESSAGE
          puts "#{addr}> #{message}"

        when RequestType::CONNECT
          private_ip, private_port = message.chomp.split(':')
          @peers << Peer.new(private_ip:,
                             private_port:,
                             public_ip:,
                             public_port:)
          puts "== Peer #{addr} is connected =="

        when RequestType::DISCONNECT
          @peers.reject! do |peer|
            [public_ip, public_port] == [peer.public_ip, peer.public_port]
          end
          puts "== Peer #{addr} is disconnected =="
        end
      end
    end

    def read_loop
      loop do
        send2peers Readline.readline('> ', true)
      end
    end

    def run
      connect
      threads = [
        Thread.new { keep_alive_loop },
        Thread.new { recv_loop },
        Thread.new { read_loop }
      ]
      threads.each(&:join)
    rescue Interrupt
      threads&.each(&:kill)
      send2server request_type: RequestType::DISCONNECT
      send2peers request_type: RequestType::DISCONNECT
      @socket.close
    end

    def send2server(message = '', request_type: RequestType::CONNECT)
      @socket.send "#{request_type} #{message}",
                   flags,
                   @server_ip,
                   @server_port
    end

    def peer_is_me(peer)
      [peer.private_ip, peer.private_port] == [ip_address, @port]
    end

    def send2peers(message = '', request_type: RequestType::MESSAGE)
      message = "#{request_type} #{message}"
      @peers.reject { peer_is_me _1 }
            .each do |peer|
        @socket.send message,
                     flags,
                     peer.private_ip,
                     peer.private_port

      rescue Errno::EDESTADDRREQ
        @socket.send message,
                     flags,
                     peer.public_ip,
                     peer.public_port
      end
    end

    def puts(*args)
      print "\r"
      $stdout.puts(*args)
      Readline.refresh_line
    end
  end
end
