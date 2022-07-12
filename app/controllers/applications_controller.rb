class ApplicationsController < ApplicationController
  before_action :set_application, only: [:show, :update, :destroy]

  # GET /applications
  def index
    @applications = Application.all
    json_response(@applications)
  end

  # POST /applications
  def create
    @application = ApplicationModelCreator.create(application_params)
    @application.save!
    json_response({name: @application.name, token: @application.token}, :created)
  end

  # GET /applications/:token
  def show
    json_response({name: @application.name, token: @application.token})
  end

  # PUT /applications/:token
  def update
    @application.update(application_params)
    head :no_content
  end

  # DELETE /applications/:token
  def destroy
    @application.destroy
    head :no_content
  end

  private

  def application_params
    # whitelist params
    params.permit(:name)
  end

  def set_application
    @application = Application.find_by!(token: params[:token])
  end
end
