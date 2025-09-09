class ApplicationMailer < ActionMailer::Base
  prepend_view_path "app/views/mailers"
  default from: "no-reply@biorepository.lsa.umich.edu",
          reply_to: -> { reply_to_email },
          to: "lsa-biorepository-super-admins@umich.edu"
  layout "mailer"

  private

  def reply_to_email
    email = GlobalPreference.find_by(name: "generic_contact_email")&.value
    if email.present?
      email
    else
      'lsa-biorepository-super-admins@umich.edu'
    end
  end

end
