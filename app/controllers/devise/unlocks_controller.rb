class Devise::UnlocksController < ApplicationController
  prepend_before_filter :require_no_authentication
  include Devise::Controllers::InternalHelpers

  # GET /resource/unlock/new
  def new
    build_resource({})
    render_with_scope :new
  end

  # POST /resource/unlock
  def create
    self.resource = resource_class.send_unlock_instructions(params[resource_name])

    if resource.errors.empty?
      set_flash_message :notice, :send_instructions if is_navigational_format?
      respond_with resource, :location => new_session_path(resource_name)
    else
      respond_with(resource) do |format|
        format.any(*navigational_formats) { render_with_scope :new }
      end
    end
  end

  # GET /resource/unlock?unlock_token=abcdef
  def show
    self.resource = resource_class.unlock_access_by_token(params[:unlock_token])

    if resource.errors.empty?
      set_flash_message :notice, :unlocked if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with(resource) do |format|
        format.any(*navigational_formats) { redirect_to redirect_location(resource_name, resource) }
      end
    else
      respond_with(resource.errors, :status => :unprocessable_entity) do |format|
        format.any(*navigational_formats) { render_with_scope :new }
      end
    end
  end
end
