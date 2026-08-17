Rails.application.config.to_prepare do
   return unless defined?(LsaTdxFeedback::FeedbackController)
  LsaTdxFeedback::FeedbackController.class_eval do
    next if instance_variable_defined?(:@_lsa_tdx_feedback_callbacks_added)
    # The gem controller inherits from ApplicationController, so prevent app-level
    # auth/cart callbacks from blocking anonymous feedback posts.
    skip_before_action :authenticate_user!, only: :create, raise: false
    skip_before_action :set_render_checkout, only: :create, raise: false
    skip_before_action :initialize_checkout, only: :create, raise: false
    skip_before_action :set_checkout_active_count, only: :create, raise: false
    skip_before_action :make_q, only: :create, raise: false

    skip_before_action :authorize_feedback, raise: false
    before_action :authorize_feedback, only: :create
    @_lsa_tdx_feedback_callbacks_added = true

    private
    
    def authorize_feedback
      authorize :feedback
    end
  end
end
