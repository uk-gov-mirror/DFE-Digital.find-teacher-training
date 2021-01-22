module ResultFilters
  class ProviderController < ApplicationController
    include FilterParameters

    def new
      if params[:query].blank?
        flash[:error] = [t('location_filter.fields.provider'), t('location_filter.errors.blank_provider')]
        return redirect_back
      end

      if params[:query].length == 1
        flash[:error] = [t('location_filter.fields.provider'), t('location_filter.errors.missing_provider')]
        return redirect_back
      end

      @provider_suggestions = ProviderSuggestion
        .select(:code, :name)
        .where(recruitment_cycle_year: Settings.current_cycle)
        .with_params(query: params[:query])
        .all

      if @provider_suggestions.count.zero?
        flash[:error] = [I18n.t('location_filter.fields.provider'), I18n.t('location_filter.errors.missing_provider')]
        redirect_back
      elsif @provider_suggestions.count == 1
        redirect_to results_path(
          filter_params_without_previous_parameters.merge(query: @provider_suggestions.first.name),
        )
      end
    end

    def redirect_back
      redirect_params = filter_params
      redirect_params = redirect_params.except(:query) if params[:query].blank?

      if flash[:start_wizard]
        redirect_to root_path(redirect_params)
      else
        redirect_to location_path(redirect_params)
      end
    end
  end
end
