# frozen_string_literal: true

require_relative 'request_type'
require_relative 'client'
require_relative 'util'

module P2PChat
  class CLIClient
    attr_reader :port,
                :server_ip,
                :server_port,
                :socket,
                :peers,
                :flags,
                :ip_address,
                :prompt_symbol

    def initialize(port:, server_ip:, server_port:, message_len:,
                   keep_alive_sleep_duration:, flags:, prompt_symbol:)
      @prompt_symbol = prompt_symbol
      @keep_alive_sleep_duration = keep_alive_sleep_duration

      @client = Client.new(port:,
                           server_ip:,
                           server_port:,
                           message_len:,
                           keep_alive_sleep_duration:,
                           flags:)

      @client.listener.on RequestType::MESSAGE, &method(:on_message)
      @client.listener.on RequestType::CONNECT, &method(:on_connect)
      @client.listener.on RequestType::DISCONNECT, &method(:on_disconnect)
      @client.on :connect, &method(:on_client_connect)
    end

    def start
      @threads = [
        Thread.new { @client.start },
        Thread.new { loop { keep_alive } },
        Thread.new { loop { send_line } }
      ]
      @threads.each(&:join)
      stop
    end

    def stop
      @threads.each(&:kill)
      @client.stop
    end

    def puts(*args)
      print "\r"
      $stdout.puts(*args)
      Readline.refresh_line
    end

    private

    def send_line
      @client.send2peers Readline.readline(
        "#{Util.addr(@client.ip_address, @client.port)}#{@prompt_symbol}",
        true
      )
    end

    def keep_alive
      sleep @keep_alive_sleep_duration
      @client.send2server request_type: RequestType::KEEP_ALIVE
    end

    def on_connect(_message, public_ip, public_port)
      puts "\e[1;32m* Peer #{Util.addr(public_ip,
                                       public_port)} is connected\e[0m"
    end

    def on_disconnect(_message, public_ip, public_port)
      puts "\e[1;31m* Peer #{Util.addr(public_ip,
                                       public_port)} is disconnected\e[0m"
    end

    def on_message(message, public_ip, public_port)
      puts "#{Util.addr(public_ip, public_port)}#{@prompt_symbol}#{message}"
    end

    def on_client_connect
      @client.peers.each do |peer|
        puts "\e[1;32m* Peer #{Util.addr(peer.public_ip,
                                         peer.public_port)} is connected\e[0m"
      end
      size = @client.peers.size
      num = size == 0 ? 'None' : size
      ending = size == 1 ? '' : 's'
      to_be = size == 1 ? 'is' : 'are'
      puts "\e[1;32m* #{num} peer#{ending} #{to_be} connected\e[0m"
    end
  end
end
