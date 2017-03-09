module Administrate
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def index
      resources = Filter.apply(resource_resolver, filters)
      resources = order.apply(resources)
      resources = customize_resource_fetching(resources)
      resources = resources.page(params[:page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)

      render locals: {
        resources: resources,
        page:      page
      }
    end

    def show
      render locals: {
        page: show_page
      }
    end

    def new
      render locals: {
        page: new_form
      }
    end

    def edit
      render locals: {
        page: edit_page
      }
    end

    def create
      if save_resource_on_create(new_resource)
        if request.xhr?
          head :ok
        else
          redirect_to(
            after_create_path,
            notice: translate_with_resource("create.success"),
          )
        end
      else
        if request.xhr?
          head :unprocessable_entity
        else
          render :new, locals: {
            page: create_form
          }
        end
      end
    end

    def update
      requested_resource.attributes = resource_params
      if save_resource_on_update(requested_resource)
        if request.xhr?
          head :ok
        else
          redirect_to(
            [namespace, requested_resource],
            notice: translate_with_resource("update.success"),
          )
        end
      else
        if request.xhr?
          head :unprocessable_entity
        else
          render :edit, locals: {
            page: edit_page
          }
        end
      end
    end

    def destroy
      requested_resource.destroy
      if request.xhr?
        head :ok
      else
        flash[:notice] = translate_with_resource("destroy.success")
        redirect_to action: :index
      end
    end

    private

    helper_method def filters
      Hash(params[:filters]).map do |key, value|
        Filter::Finder.new(resource_resolver, key).find_and_assign_value(value)
      end
    end

    helper_method def nav_link_state(resource)
      if resource_name.to_s.pluralize == resource.to_s
        :active
      else
        :inactive
      end
    end

    def records_per_page
      params[:per_page] || 20
    end

    def default_order
    end

    def default_direction
    end

    def order
      @_order ||= Administrate::Order.new(params[:order]     || default_order,
                                          params[:direction] || default_direction)
    end

    helper_method def dashboard
      @_dashboard ||= resource_resolver.dashboard_class.new
    end

    def requested_resource
      @_requested_resource ||= find_resource(params[:id])
    end

    def new_resource
      @_new_resource ||= resource_class.new(resource_params)
    end

    def initialized_resource
      @_initialized_resource ||= resource_class.new(params.permit(*permitted_attributes))
    end

    def show_page
      @_show_page ||= Administrate::Page::Show.new(dashboard, requested_resource)
    end

    def edit_page
      @_edit_page ||= Administrate::Page::Form.new(dashboard, requested_resource)
    end

    def new_form
      @_new_form ||= Administrate::Page::Form.new(dashboard, initialized_resource)
    end

    def create_form
      @_create_form ||= Administrate::Page::Form.new(dashboard, new_resource)
    end

    def find_resource(param)
      resource_class.find(param)
    end

    def save_resource_on_create(resource)
      save_resource(resource)
    end

    def save_resource_on_update(resource)
      save_resource(resource)
    end

    def save_resource(resource)
      resource.save
    end

    def resource_params
      params.require(resource_name).permit(*permitted_attributes)
    end

    def permitted_attributes
      dashboard.permitted_attributes(params[:action])
    end

    delegate :resource_class, :resource_name, :namespace, to: :resource_resolver
    helper_method :namespace
    helper_method :resource_name

    def resource_resolver
      @_resource_resolver ||=
        Administrate::ResourceResolver.new(controller_path)
    end

    def translate_with_resource(key)
      t(
        "administrate.controller.#{key}",
        resource: resource_resolver.resource_title,
      )
    end

    # Override this method in your resource controller
    # to apply `includes` or `eager_load`
    def customize_resource_fetching(resources)
      resources
    end

    # Override this method in your resource controller
    # to redirect somewhere else.
    def after_create_path
      [namespace, new_resource]
    end
  end
end
