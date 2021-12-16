# ActiveOperation

[![Gem Version](https://badge.fury.io/rb/active_operation.svg)](https://rubygems.org/gems/active_operation)
[![Downloads](http://ruby-gem-downloads-badge.herokuapp.com/active_operation?type=total)](https://rubygems.org/gems/active_operation)

`ActiveOperation` is a micro-framework for modelling business processes.
It is the perfect companion for any Rails application.
The main idea behind an operation is to move code that traditionally either lives in a controller or a model into a dedicated object.
Multiple operations can be combined into a pipeline.
This helps with structuring large business processes and aids reusability.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_operation'
```

And then execute:

```
$ bundle
```

Or install it manually as:

```
$ gem install active_operation
```

### Rails

Run the the install generator to initialize a base operation:

```
rails g active_operation:install
```

Then generate the desired operation:

```
rails g active_operation:operation signup/create_user
```

## Usage

We will first look at defining and using a single operation and then explore how to combine multiple operations into a pipeline.

### Defining and using a single operation

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
This method will return the operation's output, which is also available through the `#output` method.
For convenience, operations also expose a `.call` class method, which instantiates the operation, runs it and returns its output.

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

### Defining and using pipelines

Continuing with the example above, given the two operations, `User::Signup` and `Email::SendWelcomeEmail`, a pipeline can be defined as follows:

```ruby
class OnboardUser < ActiveSupport::Pipeline
  use User::Signup
  use Email::SendWelcomeEmail
end
```

The pipeline derives its inputs from the first operation – in this case `User::Signup`.
Similarly, the pipeline's output is simply the output of the last operation.
All operations beyond the first operation are expected to take its predecessors output as input.
In the example above, `User::Signup` produces a `User` record that `Email::SendWelcomeEmail` takes as input.

Pipeline themselves are operations and can therefore be invoked like any other operations.

```ruby
OnboardUser.call(email: "john@doe.com", password: "123456")
```

Furthermore, since pipelines are operations themselves, they can also be used within other pipelines.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/t6d/active_operation.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
