class Devise::UnlocksController < DeviseController
  prepend_before_filter :require_no_authentication

  # GET /resource/unlock/new
  def new
    build_resource({})
  end

  # POST /resource/unlock
  def create
    self.resource = resource_class.send_unlock_instructions(params[resource_name])

    if successfully_sent?(resource)
      respond_with({}, :location => after_sending_reset_unlock_instructions_path_for(resource))
    else
      respond_with(resource)
    end
  end

  # GET /resource/unlock?unlock_token=abcdef
  def show
    self.resource = resource_class.unlock_access_by_token(params[:unlock_token])

    if resource.errors.empty?
      set_flash_message :notice, :unlocked if is_navigational_format?
      respond_with_navigational(resource){ redirect_to after_sending_reset_unlock_instructions_path_for(resource) }
    else
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
  end

  protected

    # The path used after sending unlock password instructions
    def after_sending_reset_unlock_instructions_path_for(resource)
      new_session_path(resource)
    end

end
