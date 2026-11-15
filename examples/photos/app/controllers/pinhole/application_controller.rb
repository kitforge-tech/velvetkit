module Pinhole
  class ApplicationController < ActionController::Base
    helper Pinhole::LibraryHelper
    helper_method :library

    private

    def library = @library ||= Library.new(session)
  end
end
