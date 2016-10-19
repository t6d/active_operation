# ActiveOperation
[![Gem Version](https://badge.fury.io/rb/active_operation.svg)](https://rubygems.org/gems/active_operation)
[![Downloads](http://ruby-gem-downloads-badge.herokuapp.com/active_operation?type=total)](https://rubygems.org/gems/active_operation)

`ActiveOperation` is a micro-framework for modelling business processes.
It is the perfect companion for any Rails application.
The core idea behind an operation is to move code that usually would either live in a controller or a model into a dedicated object.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_operation', '~> 0.1.0'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install active_operation
```

### Rails

We recommend running the install generator to initialize a base operation:

```
rails g active_operation:install
```

You can also generate new operations using:

```
rails g active_operation:operation Signup
```

## Usage

To define an operation, create a new class and inherit from `ActiveOperation::Base`.
The input arguments of an operation are defined using the `input` statement.
These statements describe the arguments the initializer takes.
All arguments are accessible through reader and writer methods.
`ActiveOperation` uses `SmartProperties` to provide this feature.
More information on the available configuration options can be found in the project [README](https://github.com/t6d/smart_properties).

Every operation must implement the `#execute` method, which describes its core functionality.
Additionally, operations support the following callbacks: `before`, `around`, `after`, `succeeded`, `halted`, `error`.
The callback mechanism utilizes `ActiveSupport::Callbacks`.
Thus, everything known from Rails is applicable for operation callbacks, too.

```ruby
# app/operations/user/signup.rb
class User::Signup < ActiveOperation::Base
  input :email, accepts: String, type: :keyword, required: true
  input :password, accepts: String, type: :keyword, required: true

  before do
    user = User.find_by(email: email)
    halt user unless user.nil?
  end

  def execute
    User.create!(email: email, password: password)
  end

  succeeded do
    Email::SendWelcomeMail.perform(output)
  end
end
```

To execute an operation, instantiate it and invoke the `#call` method.
As a result, this method will return the operation's output, which is also available through the `#output` method.
For convenience, operations also expose a `.call` class method, which instantiates the operation, runs it and returns the its output.

Operations go through different states during their lifecycle.
After executing an operation, the state can be used for branching purposes.
In the example below, the operation's state is used to decide wether to redirect to the `user_path` or to re-render the `new` page.

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    signup = User::Signup.new(**signup_params)
    @user = signup.call

    if signup.succeeded?
      redirect_to user_path(@user)
    else
      flash[:error] = "Could not create user"
      render :new
    end
  end

  private

  def signup_params
    params.permit(:email, :password)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/t6d/active_operation.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
