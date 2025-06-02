class RequestsController < ApplicationController

  def information_request
    @information_request = InformationRequest.new
    @send_to = Collection.pluck(:admin_group).compact
  end

  def send_information_request
    fail
  end
end
