# LenovoWarrantyScraper


## Installation

Install Firefox and Geckodriver
./install_geckodriver.sh is included. See source for install path.
https://chocolatey.org/packages/selenium-gecko-driver



## Usage

* Copy config/secrets.yaml.sample to config/secrets.yaml and configure
* Copy config/serial_number_input.csv.sample to config/serial_number_input.csv
* Copy config/claims.csv.sample to config/claims.csv

Fill out csv config files listed above

Run lib/LenovoWarrantyScraper.rb

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/LenovoWarrantyScraper.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
