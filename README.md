# Compatibility Tests of WordPress and PHP

https://travis-ci.org/miya0001/wp-compatibility-tests

It runs PHPUnit tests for WordPress 3.7+ and PHP 5.3+ on the Travis CI.

You can see compatibilities of PHP versions from 5.3 to 7.0 with WordPress versions from 3.7 to latest.

## How to run tests

```
$ git clone git@github.com:miya0001/wp-compatibility-tests.git
$ bash bin/install-wp-tests.sh wordpress_test root '' localhost 4.6
$ cd tests
$ phpunit
```
