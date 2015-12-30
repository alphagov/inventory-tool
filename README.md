# Content Inventory Automation

App for generating and updating spreadsheets used in making an inventory of govuk documents on a specific subject or subjects.

## Technical documentation

This is a Heroku Ruby on Rails application that maintains a database of spreadsheets that the 
application has created, and other data.  The app uses GoogleDrive gem to create and 
update the spreadsheets.

### Dependencies

* redis
* postgresql

### Running the application

    redis-server
    bundle exec sidekiq
    bundle exec rails s


### Running the test suite

`bundle exec rake`

## Licence

[MIT License](LICENCE)


## Authentication

See the wiki: https://gov-uk.atlassian.net/wiki/pages/createpage.action?spaceKey=FS&fromPageId=44761298


