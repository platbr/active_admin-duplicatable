require "active_admin"
require "active_admin/duplicatable/version"

module ActiveAdmin
  module Duplicatable

    extend ActiveSupport::Concern

    # Public: Enable and configure resource duplication
    #
    # options - Duplication options (default: { via: :form }):
    #           :via - Method of duplication. Via `:save` is the only way to
    #                  copy a resources relations not present in the form.
    #
    # Examples
    #
    #   ActiveAdmin.register Post do
    #     duplicatable via: :save
    #   end
    #
    def duplicatable(options = {})
      via = options.fetch(:via) { :form }

      if via == :save
        enable_resource_duplication_via_save
      else
        enable_resource_duplication_via_form
      end
    end

    private

    # Enables resource duplication via new form.
    #
    # - Adds a duplicate action button.
    # - Preloads a duplicated resource on `:new` to pre-fill the form fields.
    #
    # No return.
    def enable_resource_duplication_via_form
      action_item :only => [:show] do
        link_to(I18n.t(:duplicate_model, default: "Duplicate %{model}", scope: [:active_admin], model: active_admin_config.resource_label), action: :new, _source_id: resource.id)
      end

      controller do
        before_filter only: :new do
          if !params[:_source_id].blank?
            source = resource_class.find(params[:_source_id])
            @resource ||= source.amoeba_dup if source
          end
        end
      end
    end

    # Enables resource duplication via save.
    #
    # - Adds a duplicate action button.
    # - Duplicates a resource, persists it, and redirects the user to edit
    #   the newly duplicated resource.
    #
    # No return.
    def enable_resource_duplication_via_save
      action_item :only => [:show] do
        link_to(I18n.t(:duplicate_model, default: "Duplicate %{model}", scope: [:active_admin], model: active_admin_config.resource_label), action: :duplicate)
      end

      member_action :duplicate do
        resource  = resource_class.find(params[:id])
        duplicate = resource.amoeba_dup
        if duplicate.save
          redirect_to({ action: :edit, id: duplicate.id }, flash: { notice: "#{active_admin_config.resource_label} was successfully duplicated." })
        else
          redirect_to({ action: :show }, flash: { error: "#{active_admin_config.resource_label} could not be duplicated." })
        end
      end
    end

  end
end

ActiveAdmin::ResourceDSL.send :include, ActiveAdmin::Duplicatable