This is a bunch of tools and utilities to help developing Rails apps using
tools like SimpleRecord, jquery, OpenID, Oauth, HTML5, etc.

Everything is mix-ins and methods so you can pick and choose what you want to use.

## Features

- Super easy OpenID and Facebook logins
- User authentication
- Timezone helpers
- Sharing things in an app (Shareable mix-in)
- Ready to go models (User)
- Geolocation
- API authentication to easily create secure API's

## Installation and Configuration

Clone appoxy BASE project.

OR:

- gem 'appoxy_rails'
- Delete all prototype scripts in public/javascripts


## Includes

### User

Create a User model and extend `< Appoxy::Sessions::User`

### ApplicationController

Add `include Appoxy::Sessions::ApplicationController` to your ApplicationController.

### ApplicationHelper

Add `include Appoxy::UI::ApplicationHelper` to your ApplicationHelper.

Includes:

- Date formatting based on current user's timezone.
- flash_messages
- error_messages_for

### UsersController

Add `include Appoxy::Sessions::UsersController` to your SessionsController.

Includes:

- User creation.
- Timezone setting.
- Geo location setting.

#### Callbacks

- before_create
- after_create

### SessionsController

Add `include Appoxy::Sessions::SessionsController` to your SessionsController.

Includes:

- Authentication
- Password resetting
- Logout

#### Callbacks

- before_create
- after_create
- after_reset_password - good for sending out an email, eg: Mailer.deliver_reset_password(@user, @newpass)

### appoxy_javascripts

Includes:

- jquery
- jquery ui

### appoxy_header

Includes:

- appoxy_javascripts

### appoxy_footer

Includes:

- Some debug stuff if in development environment.
- Timezone script to get user timezone.

## Authentication

Any controllers that require authentication to view, use:

    before_filter :authenticate

### OpenID

### Facebook

### Oauth

## Sharing

