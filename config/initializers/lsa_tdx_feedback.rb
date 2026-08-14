Rails.application.reloader.to_prepare do
  LsaTdxFeedback::FeedbackController.class_eval do
    # The gem controller inherits from ApplicationController, so prevent app-level
    # auth/cart callbacks from blocking anonymous feedback posts.
    skip_before_action :authenticate_user!, only: :create, raise: false
    skip_before_action :set_render_checkout, only: :create, raise: false
    skip_before_action :initialize_checkout, only: :create, raise: false
    skip_before_action :set_checkout_active_count, only: :create, raise: false
    skip_before_action :make_q, only: :create, raise: false

    before_action -> { authorize :feedback }, only: :create
  end
end
