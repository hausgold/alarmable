### next

* TODO: Replace this bullet point with an actual description of a change.

### 2.7.0 (18 February 2026)

* Upgraded PostgreSQL to 18.2 ([#33](https://github.com/hausgold/alarmable/pull/33))
* Dropped 3rd-level gem dependencies which are not directly used
  by this gem ([#34](https://github.com/hausgold/alarmable/pull/34))

### 2.6.0 (28 January 2026)

* Dropped Rails 7.1 support ([#32](https://github.com/hausgold/alarmable/pull/32))

### 2.5.0 (19 January 2026)

* Corrected some Rubocop glitches

### 2.4.0 (7 January 2026)

* Upgraded to Ubuntu 24.04 on Github Actions ([#31](https://github.com/hausgold/alarmable/pull/31))
* Migrated to hausgold/actions@v2 ([#30](https://github.com/hausgold/alarmable/pull/30))

### 2.3.0 (26 December 2025)

* Added Ruby 4.0 support ([#29](https://github.com/hausgold/alarmable/pull/29))
* Dropped Ruby 3.2 and Rails 7.1 support ([#28](https://github.com/hausgold/alarmable/pull/28))

### 2.2.0 (19 December 2025)

* Upgraded PostgreSQL to 18.1. ([#26](https://github.com/hausgold/alarmable/pull/26))
* Migrated to a shared Rubocop configuration for HAUSGOLD gems ([#27](https://github.com/hausgold/alarmable/pull/27))

### 2.1.0 (24 October 2025)

* Upgraded PostgreSQL to 17.6. ([#23](https://github.com/hausgold/alarmable/pull/23))
* Dropped Reek. ([#24](https://github.com/hausgold/alarmable/pull/24))
* Added support for Rails 8.1 ([#25](https://github.com/hausgold/alarmable/pull/25))

### 2.0.0 (28 June 2025)

* Upgraded PostgreSQL to 17.5. ([#20](https://github.com/hausgold/alarmable/pull/20))
* Corrected some RuboCop glitches ([#21](https://github.com/hausgold/alarmable/pull/21))
* Drop Ruby 2 and end of life Rails (<7.1) ([#22](https://github.com/hausgold/alarmable/pull/22))

### 1.6.1 (21 May 2025)

* Corrected some RuboCop glitches ([#17](https://github.com/hausgold/alarmable/pull/17))
* Upgraded PostgreSQL to 17.4. ([#18](https://github.com/hausgold/alarmable/pull/18))
* Upgraded the rubocop dependencies ([#19](https://github.com/hausgold/alarmable/pull/19))

### 1.6.0 (30 January 2025)

* Added all versions up to Ruby 3.4 to the CI matrix ([#16](https://github.com/hausgold/alarmable/pull/16))

### 1.5.1 (17 January 2025)

* Added the logger dependency ([#15](https://github.com/hausgold/alarmable/pull/15))

### 1.5.0 (14 January 2025)

* Switched to Zeitwerk as autoloader ([#14](https://github.com/hausgold/alarmable/pull/14))

### 1.4.0 (12 January 2025)

* Just a retag of 1.3.0

### 1.3.0 (3 January 2025)

* Upgraded PostgreSQL to 16.4 ([#10](https://github.com/hausgold/alarmable/pull/10))
* Upgraded PostgreSQL to 16.6 ([#11](https://github.com/hausgold/alarmable/pull/11))
* Upgraded PostgreSQL to 17.2 ([#12](https://github.com/hausgold/alarmable/pull/12))
* Raised minimum supported Ruby/Rails version to 2.7/6.1 ([#13](https://github.com/hausgold/alarmable/pull/13))

### 1.2.4 (15 August 2024)

* Just a retag of 1.2.1

### 1.2.3 (15 August 2024)

* Just a retag of 1.2.1

### 1.2.2 (9 August 2024)

* Just a retag of 1.2.1

### 1.2.1 (9 August 2024)

* Added API docs building to continuous integration ([#9](https://github.com/hausgold/alarmable/pull/9))

### 1.2.0 (8 July 2024)

* Upgraded to PostgreSQL 15.2 and Redis 7.0 ([#5](https://github.com/hausgold/alarmable/pull/5))
* Moved the development dependencies from the gemspec to the Gemfile ([#6](https://github.com/hausgold/alarmable/pull/6))
* Dropped support for Ruby <2.7 ([#8](https://github.com/hausgold/alarmable/pull/8))

### 1.1.0 (24 February 2023)

* Added support for Gem release automation

### 1.0.0 (18 January 2023)

* Bundler >= 2.3 is from now on required as minimal version ([#4](https://github.com/hausgold/alarmable/pull/4))
* Dropped support for Ruby < 2.5 ([#4](https://github.com/hausgold/alarmable/pull/4))
* Dropped support for Rails < 5.2 ([#4](https://github.com/hausgold/alarmable/pull/4))
* Updated all development/runtime gems to their latest
  Ruby 2.5 compatible version ([#4](https://github.com/hausgold/alarmable/pull/4))

### 0.1.2 (15 October 2021)

* Migrated to Github Actions
* Migrated to our own coverage reporting

### 0.1.1 (12 May 2021)

* Added test coverage reports
* Corrected test coverage reports
* Corrected the simplecov config
* Configured simplecov correctly
* Switched to SVG project teasers
* Dropped support for EOL Ruby 2.2 and added 2.6
* Updated Code Climate configs ([#1](https://github.com/hausgold/alarmable/pull/1))
* Changed travis-ci.org to travis-ci.com links
* Corrected the GNU Make release target

### 0.1.0 (22 December 2017)

* Corrected a broken example on the readme
* Added initial readme file
* Set the Travis CI postgresql version to 9.6
* Added postgresql service to CI
* Corrected the Travis CI url on the readme
* Improved the Travis CI config
* Added the first implementation
* Added the code of conduct and license
* Initial commit
