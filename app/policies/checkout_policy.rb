class CheckoutPolicy < ApplicationPolicy

  def remove?
    user.checkout == record
  end
  
  def remove_unavailable?
    user.checkout == record
  end

  def remove_no_longer_available?
    user.checkout == record
  end

end
