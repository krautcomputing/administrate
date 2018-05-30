module Administrate
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    layout -> { request.xhr? ? 'administrate/xhr' : 'administrate/application' }

    def index
      resources = Filter.apply(resource_resolver, filters)
      resources = resources.includes(*resource_includes) if resource_includes.any?
      resources = order.apply(resources)
      resources = resources.page(params[:page]).per(records_per_page)

      @page = Administrate::Page::Collection.new(dashboard, order: order)

      render locals: {
        resources: resources
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

    def create(render_success_xhr_response: true)
      if save_resource_on_create(new_resource)
        flash[:notice] = translate_with_resource("create.success")
        if request.xhr?
          if render_success_xhr_response
            render json: { next: url_for(after_create_path), notice: flash[:notice] }
          end
        else
          redirect_to after_create_path
        end
      else
        if request.xhr?
          render json: { error: new_resource.errors.full_messages.join(', ') }, status: :unprocessable_entity
        else
          render :new, locals: { page: create_form }
        end
      end
    end

    def update(render_success_xhr_response: true)
      requested_resource.attributes = resource_params
      if save_resource_on_update(requested_resource)
        flash[:notice] = translate_with_resource("update.success")
        if request.xhr?
          if render_success_xhr_response
            render json: { next: url_for(after_update_path), notice: flash[:notice] }
          end
        else
          redirect_to after_update_path
        end
      else
        if request.xhr?
          render json: { error: requested_resource.errors.full_messages.join(', ') }, status: :unprocessable_entity
        else
          render :edit, locals: { page: edit_page }
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
      resource_name.to_s.pluralize == resource.to_s ? :active : :inactive
    end

    helper_method def valid_action?(name, resource = resource_class)
      routes.any? do |controller, action|
        controller == "#{namespace}/#{resource.to_s.underscore.pluralize}" && action == name.to_s
      end
    end

    # Add authorization logic to this method.
    helper_method def show_action?(action, resource)
      true
    end

    def routes
      @routes ||= Namespace.new(namespace).routes
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
      @_requested_resource ||= find_resource(params[:id]).tap do |resource|
        authorize_resource(resource)
      end
    end

    def new_resource
      @_new_resource ||= resource_class.new(resource_params).tap do |resource|
        authorize_resource(resource)
      end
    end

    helper_method def initialized_resource
      @_initialized_resource ||= resource_class.new(params.permit(*permitted_attributes)).tap do |resource|
        authorize_resource(resource)
      end
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

    def resource_includes
      dashboard.association_includes
    end

    def resource_params
      params.require(resource_class.model_name.param_key).
        permit(*permitted_attributes).
        transform_values { |v| read_param_value(v) }
    end

    def read_param_value(data)
      if data.is_a?(ActionController::Parameters) && data[:type]
        if data[:type] == Administrate::Field::Polymorphic.to_s
          GlobalID::Locator.locate(data[:value])
        else
          raise "Unrecognised param data: #{data.inspect}"
        end
      else
        data
      end
    end

    def permitted_attributes
      dashboard.permitted_attributes(params[:action])
    end

    delegate :resource_class, :resource_name, :namespace, to: :resource_resolver
    helper_method :resource_class
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
    # to redirect somewhere else.
    def after_create_path
      [namespace, new_resource]
    end

    # Override this method in your resource controller
    # to redirect somewhere else.
    def after_update_path
      [namespace, requested_resource]
    end

    # Add authorization logic to this method.
    def authorize_resource(resource)
      resource
    end
  end
end
