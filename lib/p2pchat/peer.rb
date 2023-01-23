# frozen_string_literal: true

module P2PChat
  Peer = Struct.new(:private_ip,
                    :private_port,
                    :public_ip,
                    :public_port,
                    keyword_init: true)
end
