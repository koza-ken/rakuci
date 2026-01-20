class GuidesController < ApplicationController
  def show
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end
end
