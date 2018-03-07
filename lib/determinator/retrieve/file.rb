require 'pathname'

module Determinator
  module Retrieve
    # A class which loads features from files within the initialized folder
    class File
      # @param :root [String,Pathname] The path to be used as the root to look in
      # @param :serializer [#load] A serializer which will take the string of the read file and return a Feature object.
      def initialize(root:, serializer: Determinator::Serializers::JSON )
        @root = Pathname.new(root)
        @serializer = serializer
      end

      def retrieve(feature_id)
        feature = @root.join(feature_id.to_s)
        return unless feature.exist?
        @serializer.load(feature.read)
      rescue => e
        Determinator.notice_error(e)
        nil
      end
    end
  end
end
