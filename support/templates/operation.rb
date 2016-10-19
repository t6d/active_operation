class <%= name %> < ApplicationOperation
  # input :email, accepts: String, type: :keyword, required: true
  # input :password, accepts: String, type: :keyword, required: true
  #
  # before do
  #   user = User.find_by(email: email)
  #   halt user unless user.nil?
  # end
  #
  # def execute
  #   User.create!(email: email, password: password)
  # end
  #
  # succeeded do
  #   Email::SendWelcomeMail.perform(output)
  # end
end
