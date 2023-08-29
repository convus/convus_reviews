# Welcome to Convus

This is the webapp that runs **[Convus.org](https://www.convus.org/)**

### Dependencies

_We recommend [asdf-vm](https://asdf-vm.com/#/) for managing versions of Ruby and Node. Check the [.tool-versions](.tool-versions) file to see the versions of the following dependencies that Convus uses._

- [Ruby](http://www.ruby-lang.org/en/)

- [Rails](http://rubyonrails.org/)

- [Node](https://nodejs.org/en/) & [yarn](https://yarnpkg.com/en/)

- PostgreSQL

- [Redis](http://redis.io/)

## local working

Run these commands in the terminal, from the directory the project is in.

- Install the ruby gems with `bundle install`

- Install the node packages with `yarn install`

- Create and migrate the databases `bundle exec rake db:create db:migrate db:test:prepare`

- `./start.sh` start the server.

  - [start.sh](start.sh) is a bash script. It starts Redis in the background and runs foreman with the [dev procfile](Procfile_development)

- Go to [localhost:3009](http://localhost:3009)

| Toggle in development | command                      | default  |
| ---------             | -------                      | -------  |
| Caching               | `bundle exec rails dev:cache`| disabled |
| [letter_opener][]     | `bin/rake dev:letter_opener` | enabled  |
| logging with lograge  | `bin/rake dev:lograge`       | enabled  |

[letter_opener]: https://github.com/ryanb/letter_opener

---

The source code for [convus_webapp](https://github.com/convus/convus_webapp) is licensed under [AGPL-3.0](https://github.com/convus/convus_webapp/blob/main/LICENSE).
