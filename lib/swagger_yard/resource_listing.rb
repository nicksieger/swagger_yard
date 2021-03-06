module SwaggerYard
  class ResourceListing
    attr_accessor :authorizations

    def self.all
      new(SwaggerYard.config.controller_path, SwaggerYard.config.model_path)
    end

    def initialize(controller_path, model_path)
      @model_path = model_path
      @controller_path = controller_path

      @resource_to_file_path = {}
      @authorizations = []
    end

    def models
      @models ||= parse_models
    end

    def controllers
      @controllers ||= parse_controllers
    end

    def to_h
      { "paths"               => path_objects,
        "definitions"         => model_objects,
        "tags"                => tag_objects,
        "securityDefinitions" => security_objects }
    end

    def path_objects
      controllers.map(&:apis_hash).inject({}) do |h, api_hash|
        h.merge api_hash
      end
    end

    # Resources
    def tag_objects
      controllers.map(&:to_tag)
    end

    def model_objects
      Hash[models.map {|m| [m.id, m.to_h]}]
    end

    def security_objects
      Hash[authorizations.map {|auth| [auth.name, auth.to_h]}]
    end

    private
    def parse_models
      return [] unless @model_path

      Dir[@model_path].map do |file_path|
        Model.from_yard_objects(SwaggerYard.yard_objects_from_file(file_path))
      end.compact.select(&:valid?)
    end

    def parse_controllers
      return [] unless @controller_path

      Dir[@controller_path].map do |file_path|
        create_api_declaration(file_path)
      end.select(&:valid?)
    end

    def create_api_declaration(file_path)
      yard_objects = SwaggerYard.yard_objects_from_file(file_path)

      ApiDeclaration.new(self).add_yard_objects(yard_objects)
    end
  end
end
