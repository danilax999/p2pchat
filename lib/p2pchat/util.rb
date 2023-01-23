# frozen_string_literal: true

module P2PChat
  module Util
    def self.set_value(args)
      lambda do |name, default: nil, &block|
        args[name] = default
        lambda do |value|
          args[name] = block&.call(value) || value
        end
      end
    end

    def self.private_ipv4_address
      Socket.ip_address_list
            .find(&:ipv4_private?)
            &.ip_address
    end
  end
end
