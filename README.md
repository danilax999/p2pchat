# P2PChat

P2P chat ruby implementation using UDP hole punching method.



https://user-images.githubusercontent.com/75566563/214909577-a992e1b9-d85b-41aa-9df4-5fb564d1a835.mp4



## Dependencies

- ruby-3.1+

## Installation

```bash
git clone https://github.com/danilax999/p2pchat
cd p2pchat
gem build
gem install p2pchat*.gem
```

## Usage

### Running a server

```bash
p2phat-server -p SERVER_PORT
```

> Note: make sure SERVER_PORT is open for a UDP connection.

### Running a client

```bash
p2pchat -s SERVER_IP -o SERVER_PORT -p CLIENT_PORT
```

If other peers are under the same [NAT](https://en.wikipedia.org/wiki/Network_address_translation), you will be connected to them directly.

## Documentation

See `--help` for `p2pchat` and `p2pchat-server`.

## References

- [UDP hole punching](https://en.wikipedia.org/wiki/UDP_hole_punching)
- [Peer-to-Peer Communication Across Network Address Translators](https://bford.info/pub/net/p2pnat/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
