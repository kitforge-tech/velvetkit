module Helio
  class ApplicationController < ActionController::Base
    helper Helio::DashboardHelper
    helper_method :workspace

    private

    def workspace = @workspace ||= Workspace.new(session)
  end
end
