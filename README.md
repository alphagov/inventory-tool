# Content Inventory Automation

App for generating and updating spreadsheets used in making an inventory of govuk documents on a specific subject or subjects.

It runs on heroku at http://inventory-tool.herokuapp.com/


## Technical documentation

This is a Heroku Ruby on Rails application that maintains a database of spreadsheets that the
application has created, and other data.  The app uses GoogleDrive gem to create and
update the spreadsheets.

### Dependencies

* redis
* postgresql

### Running the application

```sh
    redis-server
    bundle exec sidekiq
    USERNAME=test PASSWORD=test bundle exec rails s
```

If you are running the app in your development VM, the URL will be http://10.1.1.254:3000/

Enter the username and password that you passed in the environment variables.

### Running the test suite

```sh
bundle exec rake
```

## Deployment

This is deployed to Heroku by adding the relevant remotes and then pushing the branch

```sh
  git remote add heroku git@heroku.com:inventory-tool.git
  git push heroku master
```

or if you wanted to deploy branch with name 'my-branch'

```sh
  git push heroku my-branch:master
```


## Licence

[MIT License](LICENCE)


## Google Authentication

See the wiki: https://gov-uk.atlassian.net/wiki/pages/createpage.action?spaceKey=FS&fromPageId=44761298
