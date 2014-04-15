module DirectoryService
  module ControllerBehavior

    def index
      respond_to do |format|
        format.json { render json: DirectoryService.search_results(params[:q]) }
      end
    end

  end
end
