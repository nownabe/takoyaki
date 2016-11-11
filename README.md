# Takoyaki
Get GitHub Activities.

## Installation
```bash
gem install takoyaki
```

## Usage
Put configuration file `.takoyaki.yaml` into home directory.

```yaml
---
access_token: YOUR_ACCESS_TOKEN
repositories:
  org1:
    - repo1
    - repo2
  org2:
    - repo3
    - repo4
```

### Activities
```bash
$ tkyk activities
```

### Code Reviews
```bash
$ tkyk reviews     # only your reviews
$ tkyk reviews all # all open pull requests
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nownabe/takoyaki.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
