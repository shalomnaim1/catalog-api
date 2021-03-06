class ApplicationController < ActionController::API
  include Response
  rescue_from Catalog::TopologyError, :with => :topology_service_error
  rescue_from Catalog::NotAuthorized, :with => :not_authorized_error

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      begin
        if Tenant.tenancy_enabled?
          ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
        else
          ActsAsTenant.without_tenant { yield }
        end
      rescue KeyError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      rescue Catalog::NoTenantError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      end
    end
  end

  def current_tenant(current_user)
    tenant = current_user.tenant
    found_tenant = Tenant.find_or_create_by(:external_tenant => tenant) if tenant.present?
    return found_tenant if found_tenant
    raise Catalog::NoTenantError
  end

  def topology_service_error(err)
    render :json => {:message => err.message}, :status => :internal_server_error
  end

  def not_authorized_error(err)
    render :json => {:message => err.message}, :status => :forbidden
  end
end
