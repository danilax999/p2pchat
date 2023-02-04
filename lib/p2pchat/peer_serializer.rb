# frozen_string_literal: true

require_relative 'peer'

module P2PChat
  class PeerSerializer
    def self.serialize(peer)
      [
        "#{peer.private_ip}:#{peer.private_port}",
        "#{peer.public_ip}:#{peer.public_port}"
      ].join(' ')
    end

    def self.deserialize(str)
      str.chomp
         .split(' ')
         .map { _1.split ':' }
         .flatten(1)
         .then do |private_ip, private_port, public_ip, public_port|
        Peer.new private_ip:,
                 private_port: private_port.to_i,
                 public_ip:,
                 public_port: public_port.to_i
      end
    end
  end
end
