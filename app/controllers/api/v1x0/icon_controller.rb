module Api
  module V1x0
    class IconController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def show
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        so = ServiceOffering::Icons.new(portfolio_item.service_offering_icon_ref)
        icon = so.process.icon
        send_data(icon.data,
                  :type        => MimeMagic.by_magic(icon.data).type,
                  :disposition => 'inline')
      rescue ActiveRecord::RecordNotFound => e
        render :json => { :message => e.message }, :status => :not_found
      rescue ArgumentError
        render :json => { :message => "Icon ID not present on Portfolio Item" }, :status => :not_found
      end
    end
  end
end
